using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class City
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(10)]
    public string? PostalCode { get; set; }
    
    public int? CountryId { get; set; }
    
    public virtual Country? Country { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<Station> Stations { get; set; } = new List<Station>();
}
