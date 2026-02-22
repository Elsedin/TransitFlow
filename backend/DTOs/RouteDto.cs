namespace TransitFlow.API.DTOs;

public class RouteDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Origin { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public int TransportLineId { get; set; }
    public string TransportLineName { get; set; } = string.Empty;
    public string TransportLineNumber { get; set; } = string.Empty;
    public decimal Distance { get; set; }
    public int EstimatedDurationMinutes { get; set; }
    public bool IsActive { get; set; }
    public List<RouteStationDto> Stations { get; set; } = new();
}
