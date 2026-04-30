using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class RefundRequest
{
    [Key]
    public int Id { get; set; }

    public int UserId { get; set; }
    public virtual User? User { get; set; }

    public int TicketId { get; set; }
    public virtual Ticket? Ticket { get; set; }

    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;

    [MaxLength(50)]
    public string Status { get; set; } = "pending";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ResolvedAt { get; set; }

    public int? ResolvedByAdminId { get; set; }
    public virtual Administrator? ResolvedByAdmin { get; set; }

    [MaxLength(500)]
    public string? AdminNote { get; set; }
}

