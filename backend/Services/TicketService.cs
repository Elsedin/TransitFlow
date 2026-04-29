using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Ticket = TransitFlow.API.Models.Ticket;

namespace TransitFlow.API.Services;

public class TicketService : ITicketService
{
    private readonly ApplicationDbContext _context;

    public TicketService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TicketDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? ticketTypeId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        int? userId = null)
    {
        var now = DateTime.UtcNow;
        var query = _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(t => t.Zone)
            .Include(t => t.Transaction)
            .AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(t => t.UserId == userId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(t =>
                t.TicketNumber.ToLower().Contains(searchLower) ||
                t.User!.Email.ToLower().Contains(searchLower) ||
                t.User.Username.ToLower().Contains(searchLower));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = status.ToLower() switch
            {
                "aktivna" => query.Where(t => !t.IsUsed && t.ValidFrom <= now && t.ValidTo >= now),
                "korištena" => query.Where(t => t.IsUsed),
                "istekla" => query.Where(t => !t.IsUsed && t.ValidTo < now),
                _ => query
            };
        }

        if (ticketTypeId.HasValue)
        {
            query = query.Where(t => t.TicketTypeId == ticketTypeId.Value);
        }

        if (dateFrom.HasValue)
        {
            query = query.Where(t => t.PurchasedAt >= dateFrom.Value);
        }

        if (dateTo.HasValue)
        {
            query = query.Where(t => t.PurchasedAt <= dateTo.Value.AddDays(1).AddTicks(-1));
        }

        var tickets = await query
            .OrderByDescending(t => t.PurchasedAt)
            .ToListAsync();
        return tickets.Select(t => new TicketDto
        {
            Id = t.Id,
            PublicId = t.PublicId,
            TicketNumber = t.TicketNumber,
            UserId = t.UserId,
            UserEmail = t.User?.Email ?? string.Empty,
            TicketTypeId = t.TicketTypeId,
            TicketTypeName = t.TicketType?.Name ?? string.Empty,
            RouteId = t.RouteId,
            RouteName = t.Route != null
                ? (t.Route.TransportLine != null
                    ? $"{t.Route.TransportLine.LineNumber} - {t.Route.Origin} - {t.Route.Destination}"
                    : $"{t.Route.Origin} - {t.Route.Destination}")
                : "Sve linije",
            ZoneId = t.ZoneId,
            ZoneName = t.Zone?.Name ?? string.Empty,
            Price = t.Price,
            ValidFrom = DateTime.SpecifyKind(t.ValidFrom, DateTimeKind.Utc),
            ValidTo = DateTime.SpecifyKind(t.ValidTo, DateTimeKind.Utc),
            PurchasedAt = DateTime.SpecifyKind(t.PurchasedAt, DateTimeKind.Utc),
            IsUsed = t.IsUsed,
            UsedAt = t.UsedAt.HasValue ? DateTime.SpecifyKind(t.UsedAt.Value, DateTimeKind.Utc) : null,
            IsRefunded = t.IsRefunded,
            RefundedAt = t.RefundedAt.HasValue ? DateTime.SpecifyKind(t.RefundedAt.Value, DateTimeKind.Utc) : null,
            Status = GetTicketStatus(t, now),
            IsActive = !t.IsUsed && t.ValidFrom <= now && t.ValidTo >= now,
            PaymentMethod = t.Transaction?.PaymentMethod
        }).ToList();
    }

    public async Task<TicketDto?> GetByIdAsync(int id)
    {
        var ticket = await _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(t => t.Zone)
            .Include(t => t.Transaction)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticket == null)
            return null;

        var now = DateTime.UtcNow;
        return new TicketDto
        {
            Id = ticket.Id,
            PublicId = ticket.PublicId,
            TicketNumber = ticket.TicketNumber,
            UserId = ticket.UserId,
            UserEmail = ticket.User?.Email ?? string.Empty,
            TicketTypeId = ticket.TicketTypeId,
            TicketTypeName = ticket.TicketType?.Name ?? string.Empty,
            RouteId = ticket.RouteId,
            RouteName = ticket.Route != null
                ? (ticket.Route.TransportLine != null
                    ? $"{ticket.Route.TransportLine.LineNumber} - {ticket.Route.Origin} - {ticket.Route.Destination}"
                    : $"{ticket.Route.Origin} - {ticket.Route.Destination}")
                : "Sve linije",
            ZoneId = ticket.ZoneId,
            ZoneName = ticket.Zone?.Name ?? string.Empty,
            Price = ticket.Price,
            ValidFrom = DateTime.SpecifyKind(ticket.ValidFrom, DateTimeKind.Utc),
            ValidTo = DateTime.SpecifyKind(ticket.ValidTo, DateTimeKind.Utc),
            PurchasedAt = DateTime.SpecifyKind(ticket.PurchasedAt, DateTimeKind.Utc),
            IsUsed = ticket.IsUsed,
            UsedAt = ticket.UsedAt.HasValue ? DateTime.SpecifyKind(ticket.UsedAt.Value, DateTimeKind.Utc) : null,
            IsRefunded = ticket.IsRefunded,
            RefundedAt = ticket.RefundedAt.HasValue ? DateTime.SpecifyKind(ticket.RefundedAt.Value, DateTimeKind.Utc) : null,
            Status = GetTicketStatus(ticket, now),
            IsActive = !ticket.IsUsed && ticket.ValidFrom <= now && ticket.ValidTo >= now,
            PaymentMethod = ticket.Transaction?.PaymentMethod
        };
    }

    public async Task<TicketMetricsDto> GetMetricsAsync()
    {
        var now = DateTime.UtcNow;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);
        var sevenDaysAgo = now.AddDays(-7);

        var totalTickets = await _context.Tickets.CountAsync();
        var activeTickets = await _context.Tickets
            .CountAsync(t => !t.IsUsed && t.ValidTo >= now);
        var usedTicketsThisMonth = await _context.Tickets
            .CountAsync(t => t.IsUsed && t.UsedAt >= startOfMonth);
        var expiredTicketsLast7Days = await _context.Tickets
            .CountAsync(t => !t.IsUsed && t.ValidTo < now && t.ValidTo >= sevenDaysAgo);

        return new TicketMetricsDto
        {
            TotalTickets = totalTickets,
            ActiveTickets = activeTickets,
            UsedTicketsThisMonth = usedTicketsThisMonth,
            ExpiredTicketsLast7Days = expiredTicketsLast7Days
        };
    }

    public async Task<TicketDto> PurchaseAsync(PurchaseTicketDto dto, int userId)
    {
        var ticketType = await _context.TicketTypes.FindAsync(dto.TicketTypeId);
        if (ticketType == null)
        {
            throw new InvalidOperationException("Ticket type not found");
        }

        var route = await _context.Routes.FindAsync(dto.RouteId);
        if (route == null)
        {
            throw new InvalidOperationException("Route not found");
        }

        var zone = await _context.Zones.FindAsync(dto.ZoneId);
        if (zone == null)
        {
            throw new InvalidOperationException("Zone not found");
        }

        var ticketValidFrom = DateTime.SpecifyKind(dto.ValidFrom, DateTimeKind.Utc).ToUniversalTime();
        var ticketValidFromDate = ticketValidFrom.Date;
        
        var allPrices = await _context.TicketPrices
            .Where(tp => tp.TicketTypeId == dto.TicketTypeId 
                && tp.ZoneId == dto.ZoneId 
                && tp.IsActive)
            .ToListAsync();
        
        var ticketPrice = allPrices
            .Where(tp => 
            {
                var priceValidFrom = tp.ValidFrom.Kind == DateTimeKind.Unspecified 
                    ? DateTime.SpecifyKind(tp.ValidFrom, DateTimeKind.Utc) 
                    : tp.ValidFrom.ToUniversalTime();
                var priceValidFromDate = priceValidFrom.Date;
                
                if (priceValidFromDate > ticketValidFromDate)
                    return false;
                
                if (tp.ValidTo.HasValue)
                {
                    var priceValidTo = tp.ValidTo.Value.Kind == DateTimeKind.Unspecified 
                        ? DateTime.SpecifyKind(tp.ValidTo.Value, DateTimeKind.Utc) 
                        : tp.ValidTo.Value.ToUniversalTime();
                    var priceValidToDate = priceValidTo.Date;
                    
                    if (priceValidToDate < ticketValidFromDate)
                        return false;
                }
                
                return true;
            })
            .OrderByDescending(tp => tp.ValidFrom)
            .FirstOrDefault();

        if (ticketPrice == null)
        {
            var allPricesForCombination = await _context.TicketPrices
                .Where(tp => tp.TicketTypeId == dto.TicketTypeId && tp.ZoneId == dto.ZoneId)
                .Select(tp => new { 
                    tp.Id, 
                    tp.IsActive, 
                    tp.ValidFrom, 
                    tp.ValidTo,
                    tp.Price 
                })
                .ToListAsync();
            
            var errorDetails = $"TicketTypeId: {dto.TicketTypeId}, ZoneId: {dto.ZoneId}, " +
                              $"ValidFrom: {ticketValidFrom:yyyy-MM-dd HH:mm:ss} UTC. " +
                              $"Found {allPricesForCombination.Count} price(s) for this combination. " +
                              $"Active: {allPricesForCombination.Count(p => p.IsActive)}. " +
                              $"Details: {string.Join("; ", allPricesForCombination.Select(p => $"Id={p.Id}, Active={p.IsActive}, ValidFrom={p.ValidFrom:yyyy-MM-dd}, ValidTo={p.ValidTo?.ToString("yyyy-MM-dd") ?? "null"}"))}";
            
            throw new InvalidOperationException($"Ticket price not found for the selected ticket type and zone. {errorDetails}");
        }

        var now = DateTime.UtcNow;

        var activeSubscription = await _context.Subscriptions
            .Include(s => s.SubscriptionPackage)
            .Where(s => s.UserId == userId
                && s.Status.ToLower() == "active"
                && s.StartDate <= now
                && s.EndDate >= now)
            .OrderByDescending(s => s.EndDate)
            .FirstOrDefaultAsync();

        var subscriptionAllowsFreeTicket = activeSubscription?.SubscriptionPackage != null &&
                                           activeSubscription.SubscriptionPackage.IsActive &&
                                           activeSubscription.SubscriptionPackage.MaxZoneId >= dto.ZoneId;

        var expectedAmount = ticketPrice.Price;
        Models.Transaction? transaction = null;

        if (!subscriptionAllowsFreeTicket)
        {
            if (!dto.TransactionId.HasValue)
            {
                throw new InvalidOperationException("Transaction is required for paid ticket purchase");
            }

            transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == dto.TransactionId.Value);

            if (transaction == null)
            {
                throw new InvalidOperationException("Transaction not found");
            }

            if (transaction.UserId != userId)
            {
                throw new InvalidOperationException("Transaction does not belong to the user");
            }

            if (!string.Equals(transaction.Status, "completed", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Transaction is not completed");
            }

            if (transaction.Amount != expectedAmount)
            {
                throw new InvalidOperationException("Transaction amount does not match ticket price");
            }

            var transactionUsedByTicket = await _context.Tickets.AnyAsync(t => t.TransactionId == transaction.Id);
            var transactionUsedBySubscription = await _context.Subscriptions.AnyAsync(s => s.TransactionId == transaction.Id);
            if (transactionUsedByTicket || transactionUsedBySubscription)
            {
                throw new InvalidOperationException("Transaction has already been used");
            }
        }

        var ticketNumber = GenerateTicketNumber();

        var ticket = new Ticket
        {
            PublicId = Guid.NewGuid(),
            TicketNumber = ticketNumber,
            UserId = userId,
            TicketTypeId = dto.TicketTypeId,
            RouteId = dto.RouteId,
            ZoneId = dto.ZoneId,
            Price = subscriptionAllowsFreeTicket ? 0 : expectedAmount,
            ValidFrom = ticketValidFrom,
            ValidTo = DateTime.SpecifyKind(dto.ValidTo, DateTimeKind.Utc).ToUniversalTime(),
            PurchasedAt = DateTime.UtcNow,
            IsUsed = false,
            TransactionId = subscriptionAllowsFreeTicket ? null : transaction!.Id
        };

        _context.Tickets.Add(ticket);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(ticket.Id) ?? throw new Exception("Failed to retrieve created ticket");
    }

    public async Task<TicketValidationResultDto> ValidateAsync(Guid publicId)
    {
        var ticket = await _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(t => t.Zone)
            .FirstOrDefaultAsync(t => t.PublicId == publicId);

        if (ticket == null)
        {
            return new TicketValidationResultDto
            {
                IsValid = false,
                Status = "NotFound",
                Message = "Karta nije pronađena."
            };
        }

        var now = DateTime.UtcNow;

        if (ticket.IsRefunded)
        {
            return new TicketValidationResultDto
            {
                IsValid = false,
                Status = "Refunded",
                Message = "Karta je refundovana i ne može se koristiti.",
                Ticket = await GetByIdAsync(ticket.Id)
            };
        }

        if (ticket.ValidFrom > now)
        {
            var remaining = ticket.ValidFrom - now;
            var remainingText = FormatRemaining(remaining);
            return new TicketValidationResultDto
            {
                IsValid = false,
                Status = "NotActiveYet",
                Message = $"Karta još nije aktivna. Aktivira se za {remainingText}.",
                Ticket = await GetByIdAsync(ticket.Id)
            };
        }

        if (ticket.ValidTo < now)
        {
            return new TicketValidationResultDto
            {
                IsValid = false,
                Status = "Expired",
                Message = "Karta je istekla.",
                Ticket = await GetByIdAsync(ticket.Id)
            };
        }

        if (ticket.TicketTypeId == 1)
        {
            if (ticket.IsUsed)
            {
                return new TicketValidationResultDto
                {
                    IsValid = false,
                    Status = "AlreadyUsed",
                    Message = "Jednokratna karta je već iskorištena.",
                    Ticket = await GetByIdAsync(ticket.Id)
                };
            }

            ticket.IsUsed = true;
            ticket.UsedAt = now;
            await _context.SaveChangesAsync();

            return new TicketValidationResultDto
            {
                IsValid = true,
                Status = "Used",
                Message = "Karta je uspješno validirana i označena kao iskorištena.",
                Ticket = await GetByIdAsync(ticket.Id)
            };
        }

        if (ticket.TicketTypeId == 2)
        {
            if (!ticket.UsedAt.HasValue)
            {
                ticket.UsedAt = now;
                await _context.SaveChangesAsync();
            }
            return new TicketValidationResultDto
            {
                IsValid = true,
                Status = "Valid",
                Message = "Dnevna karta je validna u ovom periodu.",
                Ticket = await GetByIdAsync(ticket.Id)
            };
        }

        return new TicketValidationResultDto
        {
            IsValid = true,
            Status = "Valid",
            Message = "Karta je validna.",
            Ticket = await GetByIdAsync(ticket.Id)
        };
    }

    private static string FormatRemaining(TimeSpan remaining)
    {
        if (remaining.TotalSeconds < 60)
        {
            return $"{Math.Max(0, (int)Math.Ceiling(remaining.TotalSeconds))} s";
        }

        if (remaining.TotalMinutes < 60)
        {
            return $"{Math.Max(0, (int)Math.Ceiling(remaining.TotalMinutes))} min";
        }

        var hours = Math.Max(0, (int)remaining.TotalHours);
        var minutes = Math.Max(0, remaining.Minutes);
        if (minutes == 0)
        {
            return $"{hours} h";
        }

        return $"{hours} h {minutes} min";
    }

    private static string GenerateTicketNumber()
    {
        var year = DateTime.UtcNow.Year;
        var random = new Random();
        var number = random.Next(100000, 999999);
        return $"TKT-{year}-{number:D6}";
    }

    private static string GetTicketStatus(Ticket ticket, DateTime now)
    {
        if (ticket.IsUsed)
        {
            return "Korištena";
        }

        if (ticket.ValidFrom > now)
        {
            return "Neaktivna";
        }

        if (ticket.ValidTo < now)
        {
            return "Istekla";
        }

        return "Aktivna";
    }
}
