using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class TicketType
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public int ValidityDays { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public virtual ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
    
    public virtual ICollection<TicketPrice> TicketPrices { get; set; } = new List<TicketPrice>();
}
