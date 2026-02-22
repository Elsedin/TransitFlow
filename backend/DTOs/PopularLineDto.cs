namespace TransitFlow.API.DTOs;

public class PopularLineDto
{
    public string LineNumber { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public int TicketCount { get; set; }
    public decimal Revenue { get; set; }
}
