namespace TransitFlow.API.DTOs;

public class TicketTypeDistributionDto
{
    public string TicketTypeName { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal Percentage { get; set; }
    public string Color { get; set; } = string.Empty;
}
