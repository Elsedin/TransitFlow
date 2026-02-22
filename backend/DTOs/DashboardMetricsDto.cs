namespace TransitFlow.API.DTOs;

public class DashboardMetricsDto
{
    public int TotalUsers { get; set; }
    public int TotalTicketsSold { get; set; }
    public decimal TotalRevenue { get; set; }
    public int ActiveRoutes { get; set; }
}
