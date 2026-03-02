namespace TransitFlow.API.DTOs;

public class PayPalOrderResponse
{
    public string OrderId { get; set; } = string.Empty;
    public string ApprovalUrl { get; set; } = string.Empty;
    public int TransactionId { get; set; }
}
