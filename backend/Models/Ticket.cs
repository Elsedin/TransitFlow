using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class Ticket
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string TicketNumber { get; set; } = string.Empty;
    
    public int UserId { get; set; }
    
    public virtual User? User { get; set; }
    
    public int TicketTypeId { get; set; }
    
    public virtual TicketType? TicketType { get; set; }
    
    public int? RouteId { get; set; }
    
    public virtual Route? Route { get; set; }
    
    public int ZoneId { get; set; }
    
    public virtual Zone? Zone { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }
    
    public DateTime ValidFrom { get; set; }
    
    public DateTime ValidTo { get; set; }
    
    public DateTime PurchasedAt { get; set; } = DateTime.UtcNow;
    
    public bool IsUsed { get; set; } = false;
    
    public DateTime? UsedAt { get; set; }
    
    public int? TransactionId { get; set; }
    
    public virtual Transaction? Transaction { get; set; }
}
