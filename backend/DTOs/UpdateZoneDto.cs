using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateZoneDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public bool IsActive { get; set; }
}
