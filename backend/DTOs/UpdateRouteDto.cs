using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateRouteDto
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
    
    public bool IsActive { get; set; }
    
    public List<UpdateRouteStationDto> Stations { get; set; } = new();
}

public class UpdateRouteStationDto
{
    public int? Id { get; set; }
    
    [Required]
    public int StationId { get; set; }
    
    [Required]
    public int Order { get; set; }
}
