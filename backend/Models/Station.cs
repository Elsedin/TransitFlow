using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class Station
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Address { get; set; }
    
    [Column(TypeName = "decimal(10,8)")]
    public decimal? Latitude { get; set; }
    
    [Column(TypeName = "decimal(11,8)")]
    public decimal? Longitude { get; set; }
    
    public int CityId { get; set; }
    
    public virtual City? City { get; set; }
    
    public int ZoneId { get; set; }
    
    public virtual Zone? Zone { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<RouteStation> RouteStations { get; set; } = new List<RouteStation>();
}
