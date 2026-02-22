namespace TransitFlow.API.DTOs;

public class TicketMetricsDto
{
    public int TotalTickets { get; set; }
    public int ActiveTickets { get; set; }
    public int UsedTicketsThisMonth { get; set; }
    public int ExpiredTicketsLast7Days { get; set; }
}
