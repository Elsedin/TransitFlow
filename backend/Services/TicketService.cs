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
                "aktivna" => query.Where(t => !t.IsUsed && t.ValidTo >= now),
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
            ValidFrom = t.ValidFrom,
            ValidTo = t.ValidTo,
            PurchasedAt = t.PurchasedAt,
            IsUsed = t.IsUsed,
            UsedAt = t.UsedAt,
            Status = GetTicketStatus(t, now),
            IsActive = !t.IsUsed && t.ValidTo >= now,
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
            ValidFrom = ticket.ValidFrom,
            ValidTo = ticket.ValidTo,
            PurchasedAt = ticket.PurchasedAt,
            IsUsed = ticket.IsUsed,
            UsedAt = ticket.UsedAt,
            Status = GetTicketStatus(ticket, now),
            IsActive = !ticket.IsUsed && ticket.ValidTo >= now,
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

        var ticketValidFrom = dto.ValidFrom.ToUniversalTime();
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
        var hasActiveSubscription = await _context.Subscriptions
            .AnyAsync(s => s.UserId == userId 
                && s.Status.ToLower() == "active" 
                && s.StartDate <= now 
                && s.EndDate >= now);

        var ticketNumber = GenerateTicketNumber();

        var ticket = new Ticket
        {
            TicketNumber = ticketNumber,
            UserId = userId,
            TicketTypeId = dto.TicketTypeId,
            RouteId = dto.RouteId,
            ZoneId = dto.ZoneId,
            Price = hasActiveSubscription ? 0 : ticketPrice.Price,
            ValidFrom = dto.ValidFrom,
            ValidTo = dto.ValidTo,
            PurchasedAt = DateTime.UtcNow,
            IsUsed = false,
            TransactionId = hasActiveSubscription ? null : dto.TransactionId
        };

        _context.Tickets.Add(ticket);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(ticket.Id) ?? throw new Exception("Failed to retrieve created ticket");
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

        if (ticket.ValidTo < now)
        {
            return "Istekla";
        }

        return "Aktivna";
    }
}
