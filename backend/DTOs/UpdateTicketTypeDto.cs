using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateTicketTypeDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Required]
    [Range(1, int.MaxValue)]
    public int ValidityDays { get; set; }
    
    public bool IsActive { get; set; }
}
