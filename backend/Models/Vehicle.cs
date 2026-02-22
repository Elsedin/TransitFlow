using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class Vehicle
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string LicensePlate { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? Make { get; set; }
    
    [MaxLength(100)]
    public string? Model { get; set; }
    
    public int? Year { get; set; }
    
    public int Capacity { get; set; }
    
    public int TransportTypeId { get; set; }
    
    public virtual TransportType? TransportType { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
}
