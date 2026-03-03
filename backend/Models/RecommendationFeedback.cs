using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TransitFlow.API.Models;

public class RecommendationFeedback
{
    [Key]
    public int Id { get; set; }
    
    public int UserId { get; set; }
    
    public virtual User? User { get; set; }
    
    public int TransportLineId { get; set; }
    
    public virtual TransportLine? TransportLine { get; set; }
    
    public bool IsUseful { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
}
