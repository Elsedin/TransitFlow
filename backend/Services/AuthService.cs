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

    public AuthService(ApplicationDbContext context, IConfiguration configuration, ILogger<AuthService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
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
