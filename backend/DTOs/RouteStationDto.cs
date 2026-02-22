namespace TransitFlow.API.DTOs;

public class RouteStationDto
{
    public int Id { get; set; }
    public int StationId { get; set; }
    public string StationName { get; set; } = string.Empty;
    public string? StationAddress { get; set; }
    public int Order { get; set; }
}
