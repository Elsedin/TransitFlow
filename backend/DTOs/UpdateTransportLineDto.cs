using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateTransportLineDto
{
    [Required]
    [MaxLength(50)]
    public string LineNumber { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    public int TransportTypeId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Origin { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Destination { get; set; } = string.Empty;
    
    public decimal Distance { get; set; }
    
    public int EstimatedDurationMinutes { get; set; }
    
    public bool IsActive { get; set; }
}
