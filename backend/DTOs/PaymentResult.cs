namespace TransitFlow.API.DTOs;

public class PaymentResult
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public int TransactionId { get; set; }
    public string? PaymentIntentId { get; set; }
}
