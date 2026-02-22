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
        DateTime? dateTo = null)
    {
        var now = DateTime.UtcNow;
        var query = _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(t => t.Zone)
            .AsQueryable();

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
            IsActive = !t.IsUsed && t.ValidTo >= now
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
            IsActive = !ticket.IsUsed && ticket.ValidTo >= now
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
