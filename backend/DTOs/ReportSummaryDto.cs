namespace TransitFlow.API.DTOs;

public class ReportSummaryDto
{
    public int TotalTickets { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AveragePrice { get; set; }
    public int ActiveUsers { get; set; }
}
