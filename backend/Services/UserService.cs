using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;
using User = TransitFlow.API.Models.User;

namespace TransitFlow.API.Services;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly IAuthService _authService;

    public UserService(ApplicationDbContext context, IAuthService authService)
    {
        _context = context;
        _authService = authService;
    }

    public async Task<List<UserDto>> GetAllAsync(
        string? search = null,
        bool? isActive = null,
        string? sortBy = null)
    {
        var query = _context.Users
            .Include(u => u.Tickets)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(u =>
                u.Username.ToLower().Contains(searchLower) ||
                u.Email.ToLower().Contains(searchLower) ||
                (u.FirstName != null && u.FirstName.ToLower().Contains(searchLower)) ||
                (u.LastName != null && u.LastName.ToLower().Contains(searchLower)) ||
                (u.PhoneNumber != null && u.PhoneNumber.Contains(search)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(u => u.IsActive == isActive.Value);
        }

        query = sortBy?.ToLower() switch
        {
            "name" => query.OrderBy(u => u.FirstName).ThenBy(u => u.LastName),
            "email" => query.OrderBy(u => u.Email),
            "date" => query.OrderByDescending(u => u.CreatedAt),
            "purchases" => query.OrderByDescending(u => u.Tickets.Count),
            _ => query.OrderByDescending(u => u.CreatedAt)
        };

        var users = await query.ToListAsync();

        return users.Select(u => new UserDto
        {
            Id = u.Id,
            Username = u.Username,
            Email = u.Email,
            FirstName = u.FirstName,
            LastName = u.LastName,
            FullName = $"{u.FirstName ?? ""} {u.LastName ?? ""}".Trim(),
            PhoneNumber = u.PhoneNumber,
            CreatedAt = u.CreatedAt,
            LastLoginAt = u.LastLoginAt,
            IsActive = u.IsActive,
            PurchaseCount = u.Tickets.Count
        }).ToList();
    }

    public async Task<UserDto?> GetByIdAsync(int id)
    {
        var user = await _context.Users
            .Include(u => u.Tickets)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
            return null;

        return new UserDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            FullName = $"{user.FirstName ?? ""} {user.LastName ?? ""}".Trim(),
            PhoneNumber = user.PhoneNumber,
            CreatedAt = user.CreatedAt,
            LastLoginAt = user.LastLoginAt,
            IsActive = user.IsActive,
            PurchaseCount = user.Tickets.Count
        };
    }

    public async Task<UserMetricsDto> GetMetricsAsync()
    {
        var now = DateTime.UtcNow;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var totalUsers = await _context.Users.CountAsync();
        var activeUsers = await _context.Users.CountAsync(u => u.IsActive);
        var newUsersThisMonth = await _context.Users.CountAsync(u => u.CreatedAt >= startOfMonth);
        var blockedUsers = await _context.Users.CountAsync(u => !u.IsActive);

        return new UserMetricsDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            NewUsersThisMonth = newUsersThisMonth,
            BlockedUsers = blockedUsers
        };
    }

    public async Task<UserDto> CreateAsync(CreateUserDto dto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == dto.Username))
        {
            throw new InvalidOperationException("Username already exists");
        }

        if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
        {
            throw new InvalidOperationException("Email already exists");
        }

        var user = new User
        {
            Username = dto.Username.Trim(),
            Email = dto.Email.Trim().ToLower(),
            PasswordHash = AuthService.HashPassword(dto.Password),
            FirstName = string.IsNullOrWhiteSpace(dto.FirstName) ? null : dto.FirstName.Trim(),
            LastName = string.IsNullOrWhiteSpace(dto.LastName) ? null : dto.LastName.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(user.Id) ?? throw new Exception("Failed to retrieve created user");
    }

    public async Task<UserDto?> UpdateAsync(int id, UpdateUserDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return null;

        if (await _context.Users.AnyAsync(u => u.Id != id && u.Username == dto.Username))
        {
            throw new InvalidOperationException("Username already exists");
        }

        if (await _context.Users.AnyAsync(u => u.Id != id && u.Email == dto.Email))
        {
            throw new InvalidOperationException("Email already exists");
        }

        user.Username = dto.Username.Trim();
        user.Email = dto.Email.Trim().ToLower();
        user.FirstName = string.IsNullOrWhiteSpace(dto.FirstName) ? null : dto.FirstName.Trim();
        user.LastName = string.IsNullOrWhiteSpace(dto.LastName) ? null : dto.LastName.Trim();
        user.PhoneNumber = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim();
        user.IsActive = dto.IsActive;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(user.Id);
    }

    public async Task<bool> ToggleActiveAsync(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return false;

        user.IsActive = !user.IsActive;
        await _context.SaveChangesAsync();

        return true;
    }
}
