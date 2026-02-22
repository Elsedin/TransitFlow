using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class Country
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(3)]
    public string? Code { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<City> Cities { get; set; } = new List<City>();
}
