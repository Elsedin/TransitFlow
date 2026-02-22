using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateVehicleDto
{
    [Required]
    [MaxLength(50)]
    public string LicensePlate { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? Make { get; set; }
    
    [MaxLength(100)]
    public string? Model { get; set; }
    
    public int? Year { get; set; }
    
    [Required]
    [Range(1, int.MaxValue)]
    public int Capacity { get; set; }
    
    [Required]
    public int TransportTypeId { get; set; }
}
