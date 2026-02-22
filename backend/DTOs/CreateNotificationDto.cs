using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateNotificationDto
{
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string Type { get; set; } = "info";
    
    public int? UserId { get; set; }
    
    public bool SendToAllUsers { get; set; } = false;
}
