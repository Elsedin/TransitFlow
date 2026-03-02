namespace TransitFlow.API.DTOs;

public class PaymentIntentResponse
{
    public string ClientSecret { get; set; } = string.Empty;
    public string PaymentIntentId { get; set; } = string.Empty;
    public int TransactionId { get; set; }
}
