using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class AuthService : IAuthService
{
    private static readonly object PasswordHasherScope = new();
    private static readonly PasswordHasher<object> SharedHasher = new();

    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;
    private readonly IRabbitMQService _rabbitMQService;

    public AuthService(
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<AuthService> logger,
        IRabbitMQService rabbitMQService)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        var admin = await _context.Administrators
            .FirstOrDefaultAsync(a => a.Username == request.Username && a.IsActive);

        if (admin == null)
        {
            _logger.LogWarning("Admin login failed: user not found ({Username})", request.Username);
            return null;
        }

        var verification = VerifyPasswordDetailed(request.Password, admin.PasswordHash);
        if (verification == PasswordVerifyResult.Failed)
        {
            _logger.LogWarning("Admin login failed: bad password ({Username})", request.Username);
            return null;
        }

        if (verification == PasswordVerifyResult.SuccessUpgradeHash)
        {
            admin.PasswordHash = HashPassword(request.Password);
        }

        admin.LastLoginAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var token = GenerateJwtToken(admin.Username, admin.Id, role: "Administrator");
        var expiresAt = DateTime.UtcNow.AddMinutes(
            int.Parse(_configuration["Jwt:ExpirationMinutes"] ?? "60"));

        return new LoginResponse
        {
            Token = token,
            Username = admin.Username,
            ExpiresAt = expiresAt
        };
    }

    public async Task<LoginResponse?> UserLoginAsync(LoginRequest request)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => (u.Username == request.Username || u.Email == request.Username) && u.IsActive);

        if (user == null)
        {
            return null;
        }

        var verification = VerifyPasswordDetailed(request.Password, user.PasswordHash);
        if (verification == PasswordVerifyResult.Failed)
        {
            return null;
        }

        if (verification == PasswordVerifyResult.SuccessUpgradeHash)
        {
            user.PasswordHash = HashPassword(request.Password);
        }

        user.LastLoginAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var token = GenerateJwtToken(user.Username, user.Id);
        var expiresAt = DateTime.UtcNow.AddMinutes(
            int.Parse(_configuration["Jwt:ExpirationMinutes"] ?? "60"));

        return new LoginResponse
        {
            Token = token,
            Username = user.Username,
            UserId = user.Id,
            ExpiresAt = expiresAt
        };
    }

    public async Task<RegisterResponse?> RegisterAsync(RegisterRequest request)
    {
        if (await _context.Users.AnyAsync(u => u.Username == request.Username))
        {
            throw new InvalidOperationException("Username already exists");
        }

        if (await _context.Users.AnyAsync(u => u.Email == request.Email))
        {
            throw new InvalidOperationException("Email already exists");
        }

        var user = new Models.User
        {
            Username = request.Username.Trim(),
            Email = request.Email.Trim().ToLower(),
            PasswordHash = HashPassword(request.Password),
            FirstName = string.IsNullOrWhiteSpace(request.FirstName) ? null : request.FirstName.Trim(),
            LastName = string.IsNullOrWhiteSpace(request.LastName) ? null : request.LastName.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var token = GenerateJwtToken(user.Username, user.Id);
        var expiresAt = DateTime.UtcNow.AddMinutes(
            int.Parse(_configuration["Jwt:ExpirationMinutes"] ?? "60"));

        return new RegisterResponse
        {
            UserId = user.Id,
            Username = user.Username,
            Email = user.Email,
            Token = token,
            ExpiresAt = expiresAt
        };
    }

    public async Task ChangeUserPasswordAsync(int userId, ChangePasswordDto dto)
    {
        if (!string.Equals(dto.NewPassword, dto.ConfirmPassword, StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Nova lozinka i potvrda se ne poklapaju");
        }

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId && u.IsActive);
        if (user == null)
        {
            throw new KeyNotFoundException("Korisnik nije pronađen");
        }

        var verification = VerifyPasswordDetailed(dto.CurrentPassword, user.PasswordHash);
        if (verification == PasswordVerifyResult.Failed)
        {
            throw new InvalidOperationException("Trenutna lozinka nije ispravna");
        }

        user.PasswordHash = HashPassword(dto.NewPassword);
        await _context.SaveChangesAsync();
    }

    public async Task RequestPasswordResetAsync(ForgotPasswordDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email && u.IsActive);

        if (user == null)
        {
            return;
        }

        var expirationMinutes = int.Parse(_configuration["PasswordReset:ExpirationMinutes"] ?? "15");
        var resetCode = GenerateResetCode();
        var tokenHash = HashResetCode(resetCode);
        var now = DateTime.UtcNow;

        var activeTokens = await _context.PasswordResetTokens
            .Where(t => t.UserId == user.Id && t.UsedAt == null && t.ExpiresAt >= now)
            .ToListAsync();

        foreach (var token in activeTokens)
        {
            token.UsedAt = now;
        }

        _context.PasswordResetTokens.Add(new Models.PasswordResetToken
        {
            UserId = user.Id,
            TokenHash = tokenHash,
            ExpiresAt = now.AddMinutes(expirationMinutes),
            CreatedAt = now
        });

        var notification = new Models.Notification
        {
            UserId = user.Id,
            Title = "Reset lozinke",
            Message = "Poslali smo vam kod za reset lozinke na email adresu.",
            Type = "password_reset_requested",
            IsRead = false,
            CreatedAt = now,
            IsActive = true
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        var emailMessage =
            $"Vaš kod za reset lozinke je: {resetCode}. Kod važi {expirationMinutes} minuta. " +
            "Ako niste zatražili reset, ignorišite ovu poruku.";

        _rabbitMQService.PublishNotificationCreated(
            notification.Id,
            "Reset lozinke - TransitFlow",
            emailMessage,
            "password_reset",
            user.Id,
            user.Email);
    }

    public async Task ResetPasswordAsync(ResetPasswordDto dto)
    {
        if (!string.Equals(dto.NewPassword, dto.ConfirmPassword, StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Nova lozinka i potvrda se ne poklapaju");
        }

        var email = dto.Email.Trim().ToLowerInvariant();
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email && u.IsActive);

        if (user == null)
        {
            throw new InvalidOperationException("Kod za reset nije ispravan ili je istekao");
        }

        var tokenHash = HashResetCode(dto.ResetCode.Trim());
        var now = DateTime.UtcNow;

        var resetToken = await _context.PasswordResetTokens
            .Where(t => t.UserId == user.Id
                && t.TokenHash == tokenHash
                && t.UsedAt == null
                && t.ExpiresAt >= now)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (resetToken == null)
        {
            throw new InvalidOperationException("Kod za reset nije ispravan ili je istekao");
        }

        resetToken.UsedAt = now;
        user.PasswordHash = HashPassword(dto.NewPassword);
        await _context.SaveChangesAsync();
    }

    private static string GenerateResetCode()
    {
        return RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
    }

    private static string HashResetCode(string resetCode)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(resetCode.Trim()));
        return Convert.ToBase64String(bytes);
    }

    public string GenerateJwtToken(string username, int? userId = null, string? role = null)
    {
        var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured"));
        var issuer = _configuration["Jwt:Issuer"] ?? "TransitFlowAPI";
        var audience = _configuration["Jwt:Audience"] ?? "TransitFlowUsers";
        var expirationMinutes = int.Parse(_configuration["Jwt:ExpirationMinutes"] ?? "60");

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (userId.HasValue)
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, userId.Value.ToString()));
        }
        else
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, username));
        }

        if (!string.IsNullOrEmpty(role))
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims, JwtBearerDefaults.AuthenticationScheme),
            Expires = DateTime.UtcNow.AddMinutes(expirationMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key),
                SecurityAlgorithms.HmacSha256Signature)
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        return tokenHandler.WriteToken(token);
    }

    private enum PasswordVerifyResult
    {
        Failed,
        Success,
        SuccessUpgradeHash
    }

    private static bool LooksLikeLegacySha256Base64Hash(string passwordHash)
    {
        if (string.IsNullOrWhiteSpace(passwordHash))
        {
            return false;
        }

        try
        {
            var bytes = Convert.FromBase64String(passwordHash.Trim());
            return bytes.Length == 32;
        }
        catch
        {
            return false;
        }
    }

    private static bool VerifyLegacySha256(string password, string storedHash)
    {
        using var sha256 = SHA256.Create();
        var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
        var hashedPassword = Convert.ToBase64String(hashedBytes);
        return string.Equals(hashedPassword.Trim(), storedHash.Trim(), StringComparison.Ordinal);
    }

    private PasswordVerifyResult VerifyPasswordDetailed(string password, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(storedHash))
        {
            return PasswordVerifyResult.Failed;
        }

        if (LooksLikeLegacySha256Base64Hash(storedHash))
        {
            return VerifyLegacySha256(password, storedHash)
                ? PasswordVerifyResult.SuccessUpgradeHash
                : PasswordVerifyResult.Failed;
        }

        var result = SharedHasher.VerifyHashedPassword(PasswordHasherScope, storedHash, password);
        return result switch
        {
            PasswordVerificationResult.Success => PasswordVerifyResult.Success,
            PasswordVerificationResult.SuccessRehashNeeded => PasswordVerifyResult.SuccessUpgradeHash,
            _ => PasswordVerifyResult.Failed
        };
    }

    public static string HashPassword(string password)
    {
        return SharedHasher.HashPassword(PasswordHasherScope, password);
    }
}
