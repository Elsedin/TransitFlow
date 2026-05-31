namespace TransitFlow.API.Services;

public interface IPaymentPricingService
{
    Task<decimal> CalculateTicketAmountAsync(int userId, int ticketTypeId, int zoneId, DateTime validFrom);
    Task<decimal> CalculateSubscriptionAmountAsync(string packageKey);
}
