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
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo);

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
        var averagePrice = totalTickets > 0 ? totalRevenue / totalTickets : 0m;
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

    public async Task<byte[]> GenerateTicketSalesPdfAsync(ReportRequestDto request)
    {
        var report = await GenerateTicketSalesReportAsync(request);
        var from = report.DateFrom!.Value;
        var to = report.DateTo!.Value;

        var byType = report.SalesByTicketType
            .Select(x => (x.TicketTypeName, x.Count, x.Revenue))
            .ToList();

        return PdfReportBuilder.BuildTicketSalesPdf(
            report.ReportTitle,
            from,
            to,
            report.Summary.TotalTickets,
            report.Summary.TotalRevenue,
            report.Summary.AveragePrice,
            report.Summary.ActiveUsers,
            byType);
    }

    public async Task<byte[]> GenerateRefundRequestsPdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
                .ThenInclude(t => t!.Transaction)
            .Where(r => r.CreatedAt >= dateFrom && r.CreatedAt <= dateTo);

        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var total = items.Count;
        var pending = items.Count(r => r.Status == "pending");
        var approved = items.Count(r => r.Status == "approved");
        var rejected = items.Count(r => r.Status == "rejected");

        var refundedTotal = items
            .Where(r => r.Status == "approved")
            .Sum(r => r.Ticket?.Price ?? 0m);

        var rows = items.Select(r =>
        {
            var user = r.User?.Email ?? r.UserId.ToString();
            var ticketNo = r.Ticket?.TicketNumber ?? r.TicketId.ToString();
            var amount = r.Ticket?.Price ?? 0m;
            return (r.CreatedAt, user, ticketNo, amount, r.Status);
        }).ToList();

        return PdfReportBuilder.BuildRefundRequestsPdf(
            "Izvještaj o refund zahtjevima",
            dateFrom,
            dateTo,
            total,
            pending,
            approved,
            rejected,
            refundedTotal,
            rows);
    }

    private static (DateTime dateFrom, DateTime dateTo) ResolvePeriod(ReportRequestDto request)
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

        var from = dateFrom ?? DateTime.UtcNow.AddDays(-30).Date;
        var to = dateTo ?? DateTime.UtcNow.Date.AddDays(1).AddTicks(-1);
        return (from, to);
    }
}
