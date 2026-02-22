using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateCityDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(10)]
    public string? PostalCode { get; set; }
    
    public int? CountryId { get; set; }
    
    public bool IsActive { get; set; }
}
