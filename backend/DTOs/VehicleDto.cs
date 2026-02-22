namespace TransitFlow.API.DTOs;

public class VehicleDto
{
    public int Id { get; set; }
    public string LicensePlate { get; set; } = string.Empty;
    public string? Make { get; set; }
    public string? Model { get; set; }
    public int? Year { get; set; }
    public int Capacity { get; set; }
    public int TransportTypeId { get; set; }
    public string TransportTypeName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
