namespace TransitFlow.API.DTOs;

public class ZoneDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; }
    public string? Description { get; set; }
    public int StationCount { get; set; }
    public bool IsActive { get; set; }
}
