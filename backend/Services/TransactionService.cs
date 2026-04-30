using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Transaction = TransitFlow.API.Models.Transaction;

namespace TransitFlow.API.Services;

public class TransactionService : ITransactionService
{
    private readonly ApplicationDbContext _context;

    public TransactionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TransactionDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? userId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? sortBy = null)
    {
        var query = BuildFilteredQuery(search, status, userId, dateFrom, dateTo, sortBy);
        var transactions = await query.ToListAsync();
        return transactions.Select(MapToDto).ToList();
    }
    
    public async Task<PagedResultDto<TransactionDto>> GetPagedAsync(
        int page,
        int pageSize,
        string? search = null,
        string? status = null,
        int? userId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? sortBy = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;
        
        var query = BuildFilteredQuery(search, status, userId, dateFrom, dateTo, sortBy);
        var total = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<TransactionDto>
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<TransactionDto?> GetByIdAsync(int id)
    {
        var transaction = await _context.Transactions
            .Include(t => t.User)
            .Include(t => t.Tickets)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (transaction == null)
            return null;

        return new TransactionDto
        {
            Id = transaction.Id,
            TransactionNumber = transaction.TransactionNumber,
            UserId = transaction.UserId,
            UserEmail = transaction.User?.Email ?? string.Empty,
            UserFullName = $"{transaction.User?.FirstName ?? ""} {transaction.User?.LastName ?? ""}".Trim(),
            Amount = transaction.Amount,
            PaymentMethod = transaction.PaymentMethod,
            Status = transaction.Status,
            CreatedAt = transaction.CreatedAt,
            CompletedAt = transaction.CompletedAt,
            Notes = transaction.Notes,
            TicketCount = transaction.Tickets.Count,
            RefundStatus = transaction.RefundStatus,
            RefundedAt = transaction.RefundedAt,
            RefundReason = transaction.RefundReason
        };
    }

    public async Task<TransactionMetricsDto> GetMetricsAsync()
    {
        var now = DateTime.UtcNow;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var totalTransactions = await _context.Transactions.CountAsync();
        var completedTransactions = await _context.Transactions
            .CountAsync(t => t.Status.ToLower() == "completed");
        var pendingTransactions = await _context.Transactions
            .CountAsync(t => t.Status.ToLower() != "completed");
        var totalRevenue = await _context.Transactions
            .Where(t => t.Status.ToLower() == "completed")
            .SumAsync(t => (decimal?)t.Amount) ?? 0;
        var revenueThisMonth = await _context.Transactions
            .Where(t => t.Status.ToLower() == "completed" && t.CreatedAt >= startOfMonth)
            .SumAsync(t => (decimal?)t.Amount) ?? 0;

        return new TransactionMetricsDto
        {
            TotalTransactions = totalTransactions,
            CompletedTransactions = completedTransactions,
            PendingTransactions = pendingTransactions,
            TotalRevenue = totalRevenue,
            RevenueThisMonth = revenueThisMonth
        };
    }

    private IQueryable<Transaction> BuildFilteredQuery(
        string? search,
        string? status,
        int? userId,
        DateTime? dateFrom,
        DateTime? dateTo,
        string? sortBy)
    {
        var query = _context.Transactions
            .Include(t => t.User)
            .Include(t => t.Tickets)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.Trim().ToLower();
            query = query.Where(t =>
                t.TransactionNumber.ToLower().Contains(searchLower) ||
                t.User!.Email.ToLower().Contains(searchLower) ||
                t.User.Username.ToLower().Contains(searchLower));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            var s = status.Trim().ToLower();
            query = query.Where(t => t.Status.ToLower() == s);
        }

        if (userId.HasValue)
        {
            query = query.Where(t => t.UserId == userId.Value);
        }

        if (dateFrom.HasValue)
        {
            query = query.Where(t => t.CreatedAt >= dateFrom.Value);
        }

        if (dateTo.HasValue)
        {
            query = query.Where(t => t.CreatedAt <= dateTo.Value.AddDays(1).AddTicks(-1));
        }

        return sortBy?.ToLower() switch
        {
            "amount" => query.OrderByDescending(t => t.Amount),
            "date" => query.OrderByDescending(t => t.CreatedAt),
            "user" => query.OrderBy(t => t.User!.Email),
            _ => query.OrderByDescending(t => t.CreatedAt)
        };
    }

    private static TransactionDto MapToDto(Transaction t)
    {
        return new TransactionDto
        {
            Id = t.Id,
            TransactionNumber = t.TransactionNumber,
            UserId = t.UserId,
            UserEmail = t.User?.Email ?? string.Empty,
            UserFullName = $"{t.User?.FirstName ?? ""} {t.User?.LastName ?? ""}".Trim(),
            Amount = t.Amount,
            PaymentMethod = t.PaymentMethod,
            Status = t.Status,
            CreatedAt = t.CreatedAt,
            CompletedAt = t.CompletedAt,
            Notes = t.Notes,
            TicketCount = t.Tickets.Count,
            RefundStatus = t.RefundStatus,
            RefundedAt = t.RefundedAt,
            RefundReason = t.RefundReason
        };
    }
}
