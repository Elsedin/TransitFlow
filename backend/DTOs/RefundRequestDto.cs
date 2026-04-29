namespace TransitFlow.API.DTOs;

public class RefundRequestDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public int TicketId { get; set; }
    public string TicketNumber { get; set; } = string.Empty;
    public Guid TicketPublicId { get; set; }
    public string Message { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public string? AdminNote { get; set; }
}

