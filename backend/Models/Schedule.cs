using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class Schedule
{
    [Key]
    public int Id { get; set; }
    
    public int RouteId { get; set; }
    
    public virtual Route? Route { get; set; }
    
    public int VehicleId { get; set; }
    
    public virtual Vehicle? Vehicle { get; set; }
    
    [Required]
    public TimeOnly DepartureTime { get; set; }
    
    [Required]
    public TimeOnly ArrivalTime { get; set; }
    
    public DayOfWeek DayOfWeek { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
}
