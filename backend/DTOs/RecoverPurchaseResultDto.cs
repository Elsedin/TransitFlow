namespace TransitFlow.API.DTOs;

public class RecoverPurchaseResultDto
{
    public string PurchaseType { get; set; } = string.Empty;
    public TicketDto? Ticket { get; set; }
    public SubscriptionDto? Subscription { get; set; }
}
