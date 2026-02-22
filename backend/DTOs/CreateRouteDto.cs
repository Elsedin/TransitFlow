using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateRouteDto
{
    [Required]
    [MaxLength(200)]
    public string Origin { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Destination { get; set; } = string.Empty;
    
    [Required]
    public int TransportLineId { get; set; }
    
    public decimal Distance { get; set; }
    
    public int EstimatedDurationMinutes { get; set; }
    
    public List<CreateRouteStationDto> Stations { get; set; } = new();
}

public class CreateRouteStationDto
{
    [Required]
    public int StationId { get; set; }
    
    [Required]
    public int Order { get; set; }
}
