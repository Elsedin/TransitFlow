using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateZoneDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }

    [Range(1, 99)]
    public int Level { get; set; } = 1;
}
