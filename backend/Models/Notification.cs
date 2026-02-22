using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class Notification
{
    [Key]
    public int Id { get; set; }
    
    public int? UserId { get; set; }
    
    public virtual User? User { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string Type { get; set; } = string.Empty;
    
    public bool IsRead { get; set; } = false;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? ReadAt { get; set; }
    
    public bool IsActive { get; set; } = true;
}
