using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class Route
{
    [Key]
    public int Id { get; set; }
    
    public int TransportLineId { get; set; }
    
    public virtual TransportLine? TransportLine { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Origin { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Destination { get; set; } = string.Empty;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Distance { get; set; }
    
    public int EstimatedDurationMinutes { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<RouteStation> RouteStations { get; set; } = new List<RouteStation>();
    
    public virtual ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
}
