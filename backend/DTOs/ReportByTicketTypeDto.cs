namespace TransitFlow.API.DTOs;

public class ReportByTicketTypeDto
{
    public string TicketTypeName { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal Revenue { get; set; }
}
