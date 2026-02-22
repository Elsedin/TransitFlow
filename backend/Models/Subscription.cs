using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class Subscription
{
    [Key]
    public int Id { get; set; }
    
    public int UserId { get; set; }
    
    public virtual User? User { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string PackageName { get; set; } = string.Empty;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal Price { get; set; }
    
    public DateTime StartDate { get; set; }
    
    public DateTime EndDate { get; set; }
    
    [MaxLength(50)]
    public string Status { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public int? TransactionId { get; set; }
    
    public virtual Transaction? Transaction { get; set; }
}
