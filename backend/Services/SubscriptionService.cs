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

    private async Task<Models.SubscriptionPackage> ResolvePackageAsync(string packageName, CancellationToken cancellationToken = default)
    {
        var normalized = (packageName ?? string.Empty).Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Invalid package name");
        }

        var package = await _context.SubscriptionPackages
            .Where(p => p.IsActive)
            .Where(p => p.Key.ToLower() == normalized || p.DisplayName.ToLower() == normalized)
            .FirstOrDefaultAsync(cancellationToken);

        return package ?? throw new ArgumentException("Invalid package name");
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
            .Include(s => s.SubscriptionPackage)
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
            .Include(s => s.SubscriptionPackage)
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

        if (!dto.TransactionId.HasValue)
        {
            throw new ArgumentException("Transaction ID is required");
        }

        var transaction = await _context.Transactions
            .FirstOrDefaultAsync(t => t.Id == dto.TransactionId.Value);

        if (transaction == null)
        {
            throw new ArgumentException("Invalid Transaction ID");
        }

        if (transaction.UserId != dto.UserId)
        {
            throw new InvalidOperationException("Transaction does not belong to the user");
        }

        if (!string.Equals(transaction.Status, "completed", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Transaction is not completed");
        }

        var usedByAnySubscription = await _context.Subscriptions
            .AnyAsync(s => s.TransactionId == transaction.Id);

        if (usedByAnySubscription)
        {
            throw new InvalidOperationException("Transaction has already been used");
        }

        var package = await ResolvePackageAsync(dto.PackageName);

        if (transaction.Amount != package.Price)
        {
            throw new InvalidOperationException("Transaction amount does not match package price");
        }

        var now = DateTime.UtcNow;
        var activeSubscription = await _context.Subscriptions
            .Where(s => s.UserId == dto.UserId
                && s.EndDate >= now
                && s.Status.ToLower() == "active")
            .OrderByDescending(s => s.EndDate)
            .FirstOrDefaultAsync();

        var startDate = now;
        if (activeSubscription != null && activeSubscription.EndDate > now)
        {
            startDate = activeSubscription.EndDate;
        }

        var endDate = startDate.AddDays(package.DurationDays);

        var subscription = new Subscription
        {
            UserId = dto.UserId,
            SubscriptionPackageId = package.Id,
            PackageName = package.DisplayName,
            Price = package.Price,
            StartDate = startDate,
            EndDate = endDate,
            Status = "active",
            TransactionId = transaction.Id,
            CreatedAt = now
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

        var package = await ResolvePackageAsync(dto.PackageName);

        subscription.SubscriptionPackageId = package.Id;
        subscription.PackageName = package.DisplayName;
        subscription.Price = package.Price;

        if (dto.TransactionId.HasValue)
        {
            var transaction = await _context.Transactions.FirstOrDefaultAsync(t => t.Id == dto.TransactionId.Value);
            if (transaction == null)
            {
                throw new ArgumentException("Invalid Transaction ID");
            }
            subscription.TransactionId = transaction.Id;
        }

        subscription.Status = dto.Status.Trim();
        subscription.StartDate = dto.StartDate;
        subscription.EndDate = dto.EndDate;
        subscription.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<SubscriptionDto?> CancelAsync(int id)
    {
        var subscription = await _context.Subscriptions.FindAsync(id);
        if (subscription == null)
            return null;

        var now = DateTime.UtcNow;
        if (subscription.Status.ToLower() != "active" || subscription.EndDate < now)
        {
            throw new InvalidOperationException("Only active subscriptions can be cancelled");
        }

        subscription.Status = "cancelled";
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
