using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class Transaction
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string TransactionNumber { get; set; } = string.Empty;
    
    public int UserId { get; set; }
    
    public virtual User? User { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Amount { get; set; }
    
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string Status { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? CompletedAt { get; set; }
    
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    public virtual ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
}
