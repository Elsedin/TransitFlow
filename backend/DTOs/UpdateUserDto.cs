using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateUserDto
{
    [Required]
    [MaxLength(100)]
    public string Username { get; set; } = string.Empty;
    
    [Required]
    [EmailAddress]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? FirstName { get; set; }
    
    [MaxLength(100)]
    public string? LastName { get; set; }
    
    [MaxLength(20)]
    public string? PhoneNumber { get; set; }
    
    public bool IsActive { get; set; }
}
