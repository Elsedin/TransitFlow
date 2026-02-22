using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateStationDto
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Address { get; set; }
    
    public double? Latitude { get; set; }
    
    public double? Longitude { get; set; }
    
    [Required]
    public int CityId { get; set; }
    
    [Required]
    public int ZoneId { get; set; }
    
    public bool IsActive { get; set; }
}
