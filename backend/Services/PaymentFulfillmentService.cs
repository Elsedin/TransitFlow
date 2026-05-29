using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class PaymentFulfillmentService : IPaymentFulfillmentService
{
    private readonly IPaymentService _paymentService;
    private readonly ITicketService _ticketService;
    private readonly ISubscriptionService _subscriptionService;

    public PaymentFulfillmentService(
        IPaymentService paymentService,
        ITicketService ticketService,
        ISubscriptionService subscriptionService)
    {
        _paymentService = paymentService;
        _ticketService = ticketService;
        _subscriptionService = subscriptionService;
    }

    public async Task<TicketDto> FinalizeStripeTicketAsync(int userId, FinalizeTicketPaymentRequest request)
    {
        var confirm = await _paymentService.ConfirmStripePaymentAsync(request.PaymentIntentId, userId);
        if (!confirm.Success || confirm.TransactionId <= 0)
        {
            throw new InvalidOperationException(confirm.Message ?? "Payment confirmation failed");
        }

        return await _ticketService.PurchaseAsync(new PurchaseTicketDto
        {
            TicketTypeId = request.TicketTypeId,
            RouteId = request.RouteId,
            ZoneId = request.ZoneId,
            ValidFrom = request.ValidFrom,
            TransactionId = confirm.TransactionId
        }, userId);
    }

    public async Task<SubscriptionDto> FinalizeStripeSubscriptionAsync(int userId, FinalizeSubscriptionPaymentRequest request)
    {
        var confirm = await _paymentService.ConfirmStripePaymentAsync(request.PaymentIntentId, userId);
        if (!confirm.Success || confirm.TransactionId <= 0)
        {
            throw new InvalidOperationException(confirm.Message ?? "Payment confirmation failed");
        }

        return await _subscriptionService.CreateAsync(new CreateSubscriptionDto
        {
            UserId = userId,
            PackageName = request.PackageKey,
            TransactionId = confirm.TransactionId,
            Price = 0.01m,
            StartDate = DateTime.UtcNow,
            EndDate = DateTime.UtcNow.AddDays(1),
            Status = "active"
        });
    }

    public async Task<TicketDto> FinalizePayPalTicketAsync(int userId, FinalizePayPalTicketPaymentRequest request)
    {
        var capture = await _paymentService.CapturePayPalOrderAsync(request.OrderId, userId);
        if (!capture.Success || capture.TransactionId <= 0)
        {
            throw new InvalidOperationException(capture.Message ?? "PayPal capture failed");
        }

        return await _ticketService.PurchaseAsync(new PurchaseTicketDto
        {
            TicketTypeId = request.TicketTypeId,
            RouteId = request.RouteId,
            ZoneId = request.ZoneId,
            ValidFrom = request.ValidFrom,
            TransactionId = capture.TransactionId
        }, userId);
    }

    public async Task<SubscriptionDto> FinalizePayPalSubscriptionAsync(int userId, FinalizePayPalSubscriptionPaymentRequest request)
    {
        var capture = await _paymentService.CapturePayPalOrderAsync(request.OrderId, userId);
        if (!capture.Success || capture.TransactionId <= 0)
        {
            throw new InvalidOperationException(capture.Message ?? "PayPal capture failed");
        }

        return await _subscriptionService.CreateAsync(new CreateSubscriptionDto
        {
            UserId = userId,
            PackageName = request.PackageKey,
            TransactionId = capture.TransactionId,
            Price = 0.01m,
            StartDate = DateTime.UtcNow,
            EndDate = DateTime.UtcNow.AddDays(1),
            Status = "active"
        });
    }
}
