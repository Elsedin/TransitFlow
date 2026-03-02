using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IPaymentService
{
    Task<PaymentIntentResponse> CreateStripePaymentIntentAsync(decimal amount, string currency, int userId);
    Task<PaymentResult> ConfirmStripePaymentAsync(string paymentIntentId, int userId);
    Task<PayPalOrderResponse> CreatePayPalOrderAsync(decimal amount, string currency, int userId);
    Task<PaymentResult> CapturePayPalOrderAsync(string orderId, int userId);
}
