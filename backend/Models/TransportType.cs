using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class TransportType
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<TransportLine> TransportLines { get; set; } = new List<TransportLine>();
    
    public virtual ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}
