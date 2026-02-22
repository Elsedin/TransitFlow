using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class TransportLine
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string LineNumber { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    public int TransportTypeId { get; set; }
    
    public virtual TransportType? TransportType { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<Route> Routes { get; set; } = new List<Route>();
}
