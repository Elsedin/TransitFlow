using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IPaymentFulfillmentService
{
    Task<TicketDto> FinalizeStripeTicketAsync(int userId, FinalizeTicketPaymentRequest request);
    Task<SubscriptionDto> FinalizeStripeSubscriptionAsync(int userId, FinalizeSubscriptionPaymentRequest request);
    Task<TicketDto> FinalizePayPalTicketAsync(int userId, FinalizePayPalTicketPaymentRequest request);
    Task<SubscriptionDto> FinalizePayPalSubscriptionAsync(int userId, FinalizePayPalSubscriptionPaymentRequest request);
}
