using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class TicketPrice
{
    [Key]
    public int Id { get; set; }
    
    public int TicketTypeId { get; set; }
    
    public virtual TicketType? TicketType { get; set; }
    
    public int ZoneId { get; set; }
    
    public virtual Zone? Zone { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }
    
    public DateTime ValidFrom { get; set; }
    
    public DateTime? ValidTo { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
}
