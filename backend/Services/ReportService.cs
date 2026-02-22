using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Ticket = TransitFlow.API.Models.Ticket;

namespace TransitFlow.API.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _context;

    public ReportService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ReportDto> GenerateTicketSalesReportAsync(ReportRequestDto request)
    {
        var dateFrom = request.DateFrom;
        var dateTo = request.DateTo;

        if (!string.IsNullOrWhiteSpace(request.Period))
        {
            var now = DateTime.UtcNow;
            dateFrom = request.Period.ToLower() switch
            {
                "danas" => now.Date,
                "ovaj tjedan" => now.Date.AddDays(-(int)now.DayOfWeek),
                "ovaj mjesec" => new DateTime(now.Year, now.Month, 1),
                "ovaj godina" => new DateTime(now.Year, 1, 1),
                _ => dateFrom
            };
            dateTo = request.Period.ToLower() switch
            {
                "danas" => now.Date.AddDays(1).AddTicks(-1),
                "ovaj tjedan" => now.Date.AddDays(7 - (int)now.DayOfWeek).AddTicks(-1),
                "ovaj mjesec" => new DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month), 23, 59, 59),
                "ovaj godina" => new DateTime(now.Year, 12, 31, 23, 59, 59),
                _ => dateTo
            };
        }

        if (!dateFrom.HasValue)
        {
            dateFrom = DateTime.UtcNow.AddDays(-30).Date;
        }

        if (!dateTo.HasValue)
        {
            dateTo = DateTime.UtcNow.Date.AddDays(1).AddTicks(-1);
        }

        var query = _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= dateFrom.Value && t.PurchasedAt <= dateTo.Value);

        if (request.TransportLineId.HasValue)
        {
            query = query.Where(t => t.Route != null && t.Route!.TransportLineId == request.TransportLineId.Value);
        }

        if (request.TicketTypeId.HasValue)
        {
            query = query.Where(t => t.TicketTypeId == request.TicketTypeId.Value);
        }

        var tickets = await query.ToListAsync();

        var totalTickets = tickets.Count;
        var totalRevenue = tickets.Sum(t => t.Price);
        var averagePrice = totalTickets > 0 ? totalRevenue / totalTickets : 0;
        var activeUsers = tickets.Select(t => t.UserId).Distinct().Count();

        var salesByTicketType = tickets
            .GroupBy(t => new { t.TicketTypeId, TicketTypeName = t.TicketType!.Name })
            .Select(g => new ReportByTicketTypeDto
            {
                TicketTypeName = g.Key.TicketTypeName,
                Count = g.Count(),
                Revenue = g.Sum(t => t.Price)
            })
            .OrderByDescending(x => x.Revenue)
            .ToList();

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o prodaji karata",
            DateFrom = dateFrom,
            DateTo = dateTo,
            Summary = new ReportSummaryDto
            {
                TotalTickets = totalTickets,
                TotalRevenue = totalRevenue,
                AveragePrice = averagePrice,
                ActiveUsers = activeUsers
            },
            SalesByTicketType = salesByTicketType
        };
    }
}
