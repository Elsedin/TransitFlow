using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class ForgotPasswordDto
{
    [Required]
    [EmailAddress]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;
}
