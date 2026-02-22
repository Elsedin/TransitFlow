namespace TransitFlow.API.DTOs;

public class SubscriptionDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string? UserFullName { get; set; }
    public string PackageName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? TransactionId { get; set; }
    public string? TransactionNumber { get; set; }
}
