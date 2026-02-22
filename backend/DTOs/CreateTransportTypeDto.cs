using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateTransportTypeDto
{
    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
}
