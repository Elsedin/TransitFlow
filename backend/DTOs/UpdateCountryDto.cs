using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateCountryDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(3)]
    public string? Code { get; set; }

    public bool IsActive { get; set; }
}

