using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Subscription = TransitFlow.API.Models.Subscription;

namespace TransitFlow.API.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly ApplicationDbContext _context;

    public SubscriptionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<SubscriptionMetricsDto> GetMetricsAsync()
    {
        var now = DateTime.UtcNow;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var totalSubscriptions = await _context.Subscriptions.CountAsync();
        var activeSubscriptions = await _context.Subscriptions
            .CountAsync(s => s.Status.ToLower() == "active" && s.EndDate >= now);
        var expiredSubscriptions = await _context.Subscriptions
            .CountAsync(s => s.Status.ToLower() == "expired" || s.EndDate < now);
        var newSubscriptionsThisMonth = await _context.Subscriptions
            .CountAsync(s => s.CreatedAt >= startOfMonth);
        var totalRevenue = await _context.Subscriptions
            .Where(s => s.Status.ToLower() == "active" || s.Status.ToLower() == "completed")
            .SumAsync(s => (decimal?)s.Price) ?? 0;

        return new SubscriptionMetricsDto
        {
            TotalSubscriptions = totalSubscriptions,
            ActiveSubscriptions = activeSubscriptions,
            ExpiredSubscriptions = expiredSubscriptions,
            NewSubscriptionsThisMonth = newSubscriptionsThisMonth,
            TotalRevenue = totalRevenue
        };
    }

    public async Task<List<SubscriptionDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? userId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? sortBy = null)
    {
        var query = _context.Subscriptions
            .Include(s => s.User)
            .Include(s => s.Transaction)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(s =>
                s.PackageName.ToLower().Contains(searchLower) ||
                s.User!.Email.ToLower().Contains(searchLower) ||
                s.User.Username.ToLower().Contains(searchLower) ||
                (s.Transaction != null && s.Transaction.TransactionNumber.ToLower().Contains(searchLower)));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(s => s.Status.ToLower() == status.ToLower());
        }

        if (userId.HasValue)
        {
            query = query.Where(s => s.UserId == userId.Value);
        }

        if (dateFrom.HasValue)
        {
            query = query.Where(s => s.StartDate >= dateFrom.Value);
        }

        if (dateTo.HasValue)
        {
            query = query.Where(s => s.EndDate <= dateTo.Value.AddDays(1).AddTicks(-1));
        }

        query = sortBy?.ToLower() switch
        {
            "price" => query.OrderByDescending(s => s.Price),
            "date" => query.OrderByDescending(s => s.CreatedAt),
            "startdate" => query.OrderByDescending(s => s.StartDate),
            "enddate" => query.OrderByDescending(s => s.EndDate),
            "user" => query.OrderBy(s => s.User!.Email),
            _ => query.OrderByDescending(s => s.CreatedAt)
        };

        var subscriptions = await query.ToListAsync();

        return subscriptions.Select(s => new SubscriptionDto
        {
            Id = s.Id,
            UserId = s.UserId,
            UserEmail = s.User?.Email ?? string.Empty,
            UserFullName = $"{s.User?.FirstName ?? ""} {s.User?.LastName ?? ""}".Trim(),
            PackageName = s.PackageName,
            Price = s.Price,
            StartDate = s.StartDate,
            EndDate = s.EndDate,
            Status = s.Status,
            CreatedAt = s.CreatedAt,
            UpdatedAt = s.UpdatedAt,
            TransactionId = s.TransactionId,
            TransactionNumber = s.Transaction?.TransactionNumber
        }).ToList();
    }

    public async Task<SubscriptionDto?> GetByIdAsync(int id)
    {
        var subscription = await _context.Subscriptions
            .Include(s => s.User)
            .Include(s => s.Transaction)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (subscription == null)
            return null;

        return new SubscriptionDto
        {
            Id = subscription.Id,
            UserId = subscription.UserId,
            UserEmail = subscription.User?.Email ?? string.Empty,
            UserFullName = $"{subscription.User?.FirstName ?? ""} {subscription.User?.LastName ?? ""}".Trim(),
            PackageName = subscription.PackageName,
            Price = subscription.Price,
            StartDate = subscription.StartDate,
            EndDate = subscription.EndDate,
            Status = subscription.Status,
            CreatedAt = subscription.CreatedAt,
            UpdatedAt = subscription.UpdatedAt,
            TransactionId = subscription.TransactionId,
            TransactionNumber = subscription.Transaction?.TransactionNumber
        };
    }

    public async Task<SubscriptionDto> CreateAsync(CreateSubscriptionDto dto)
    {
        if (!await _context.Users.AnyAsync(u => u.Id == dto.UserId))
        {
            throw new ArgumentException("Invalid User ID");
        }

        if (dto.TransactionId.HasValue && !await _context.Transactions.AnyAsync(t => t.Id == dto.TransactionId.Value))
        {
            throw new ArgumentException("Invalid Transaction ID");
        }

        if (dto.EndDate <= dto.StartDate)
        {
            throw new ArgumentException("End date must be after start date");
        }

        var subscription = new Subscription
        {
            UserId = dto.UserId,
            PackageName = dto.PackageName.Trim(),
            Price = dto.Price,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Status = dto.Status.Trim(),
            TransactionId = dto.TransactionId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Subscriptions.Add(subscription);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(subscription.Id) ?? throw new Exception("Failed to retrieve created subscription");
    }

    public async Task<SubscriptionDto?> UpdateAsync(int id, UpdateSubscriptionDto dto)
    {
        var subscription = await _context.Subscriptions.FindAsync(id);
        if (subscription == null)
            return null;

        if (dto.TransactionId.HasValue && !await _context.Transactions.AnyAsync(t => t.Id == dto.TransactionId.Value))
        {
            throw new ArgumentException("Invalid Transaction ID");
        }

        if (dto.EndDate <= dto.StartDate)
        {
            throw new ArgumentException("End date must be after start date");
        }

        subscription.PackageName = dto.PackageName.Trim();
        subscription.Price = dto.Price;
        subscription.StartDate = dto.StartDate;
        subscription.EndDate = dto.EndDate;
        subscription.Status = dto.Status.Trim();
        subscription.TransactionId = dto.TransactionId;
        subscription.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var subscription = await _context.Subscriptions.FindAsync(id);
        if (subscription == null)
            return false;

        _context.Subscriptions.Remove(subscription);
        await _context.SaveChangesAsync();

        return true;
    }
}
