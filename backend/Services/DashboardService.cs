using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class DashboardService : IDashboardService
{
    private readonly ApplicationDbContext _context;

    public DashboardService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardMetricsDto> GetMetricsAsync()
    {
        var totalUsers = await _context.Users.CountAsync(u => u.IsActive);
        var totalTicketsSold = await _context.Tickets.CountAsync();
        var totalRevenue = await _context.Transactions
            .Where(t => t.Status == "Completed")
            .SumAsync(t => (decimal?)t.Amount) ?? 0;
        var activeTransportLines = await _context.TransportLines.CountAsync(tl => tl.IsActive);

        return new DashboardMetricsDto
        {
            TotalUsers = totalUsers,
            TotalTicketsSold = totalTicketsSold,
            TotalRevenue = totalRevenue,
            ActiveRoutes = activeTransportLines
        };
    }

    public async Task<List<TicketSalesDto>> GetTicketSalesAsync(int days = 30)
    {
        var startDate = DateTime.UtcNow.AddDays(-days);
        
        var sales = await _context.Tickets
            .Where(t => t.PurchasedAt >= startDate)
            .GroupBy(t => t.PurchasedAt.Date)
            .Select(g => new TicketSalesDto
            {
                Date = g.Key,
                Count = g.Count(),
                Revenue = g.Sum(t => t.Price)
            })
            .OrderBy(s => s.Date)
            .ToListAsync();

        return sales;
    }

    public async Task<List<TicketTypeDistributionDto>> GetTicketTypeDistributionAsync()
    {
        var totalTickets = await _context.Tickets.CountAsync();
        
        if (totalTickets == 0)
        {
            return new List<TicketTypeDistributionDto>();
        }

        var distribution = await _context.Tickets
            .Include(t => t.TicketType)
            .GroupBy(t => new { t.TicketTypeId, t.TicketType!.Name })
            .Select(g => new TicketTypeDistributionDto
            {
                TicketTypeName = g.Key.Name,
                Count = g.Count(),
                Percentage = (decimal)g.Count() / totalTickets * 100
            })
            .ToListAsync();

        var colors = new[] { "#FF6B35", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F" };
        
        for (int i = 0; i < distribution.Count; i++)
        {
            distribution[i].Color = colors[i % colors.Length];
        }

        return distribution;
    }

    public async Task<List<PopularLineDto>> GetPopularLinesAsync(int top = 5)
    {
        var popularLines = await _context.Tickets
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.Route != null && t.Route.TransportLine != null)
            .GroupBy(t => new
            {
                LineNumber = t.Route!.TransportLine!.LineNumber,
                Origin = t.Route.Origin,
                Destination = t.Route.Destination
            })
            .Select(g => new PopularLineDto
            {
                LineNumber = g.Key.LineNumber,
                Route = $"{g.Key.Origin} - {g.Key.Destination}",
                TicketCount = g.Count(),
                Revenue = g.Sum(t => t.Price)
            })
            .OrderByDescending(l => l.TicketCount)
            .Take(top)
            .ToListAsync();

        return popularLines;
    }
}
