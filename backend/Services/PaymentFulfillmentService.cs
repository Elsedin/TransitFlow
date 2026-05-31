using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Constants;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class PaymentFulfillmentService : IPaymentFulfillmentService
{
    private readonly ApplicationDbContext _context;
    private readonly IPaymentService _paymentService;
    private readonly ITicketService _ticketService;
    private readonly ISubscriptionService _subscriptionService;

    public PaymentFulfillmentService(
        ApplicationDbContext context,
        IPaymentService paymentService,
        ITicketService ticketService,
        ISubscriptionService subscriptionService)
    {
        _context = context;
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
            Status = SubscriptionStatuses.Active
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
            Status = SubscriptionStatuses.Active
        });
    }

    public async Task<List<RecoverableTransactionDto>> GetRecoverableTransactionsAsync(int userId)
    {
        var usedTransactionIds = await _context.Tickets
            .Where(t => t.TransactionId != null)
            .Select(t => t.TransactionId!.Value)
            .Union(_context.Subscriptions
                .Where(s => s.TransactionId != null)
                .Select(s => s.TransactionId!.Value))
            .ToListAsync();

        var transactions = await _context.Transactions
            .Where(t => t.UserId == userId
                && t.Status.ToLower() == TransactionStatuses.Completed
                && !usedTransactionIds.Contains(t.Id))
            .OrderByDescending(t => t.CompletedAt ?? t.CreatedAt)
            .Select(t => new RecoverableTransactionDto
            {
                TransactionId = t.Id,
                TransactionNumber = t.TransactionNumber,
                Amount = t.Amount,
                PaymentMethod = t.PaymentMethod,
                CompletedAt = t.CompletedAt ?? t.CreatedAt
            })
            .ToListAsync();

        return transactions;
    }

    public async Task<RecoverPurchaseResultDto> RecoverPurchaseAsync(int userId, RecoverPurchaseRequest request)
    {
        var transaction = await _context.Transactions.FirstOrDefaultAsync(t => t.Id == request.TransactionId);
        if (transaction == null || transaction.UserId != userId)
        {
            throw new InvalidOperationException("Transakcija nije pronađena");
        }

        if (!TransactionStatuses.Is(transaction.Status, TransactionStatuses.Completed))
        {
            throw new InvalidOperationException("Transakcija nije završena");
        }

        await EnsureTransactionUnusedAsync(transaction.Id);

        var purchaseType = (request.PurchaseType ?? string.Empty).Trim().ToLowerInvariant();

        if (purchaseType == "ticket")
        {
            if (!request.TicketTypeId.HasValue || !request.RouteId.HasValue || !request.ZoneId.HasValue || !request.ValidFrom.HasValue)
            {
                throw new ArgumentException("Kupovina karte zahtijeva ticketTypeId, routeId, zoneId i validFrom");
            }

            var ticket = await _ticketService.PurchaseAsync(new PurchaseTicketDto
            {
                TicketTypeId = request.TicketTypeId.Value,
                RouteId = request.RouteId.Value,
                ZoneId = request.ZoneId.Value,
                ValidFrom = request.ValidFrom.Value,
                TransactionId = transaction.Id
            }, userId);

            return new RecoverPurchaseResultDto
            {
                PurchaseType = purchaseType,
                Ticket = ticket
            };
        }

        if (purchaseType == "subscription")
        {
            if (string.IsNullOrWhiteSpace(request.PackageKey))
            {
                throw new ArgumentException("Kupovina pretplate zahtijeva packageKey");
            }

            var subscription = await _subscriptionService.CreateAsync(new CreateSubscriptionDto
            {
                UserId = userId,
                PackageName = request.PackageKey.Trim(),
                TransactionId = transaction.Id,
                Price = transaction.Amount,
                StartDate = DateTime.UtcNow,
                EndDate = DateTime.UtcNow.AddDays(1),
                Status = SubscriptionStatuses.Active
            });

            return new RecoverPurchaseResultDto
            {
                PurchaseType = purchaseType,
                Subscription = subscription
            };
        }

        throw new ArgumentException("Nepoznat tip kupovine");
    }

    private async Task EnsureTransactionUnusedAsync(int transactionId)
    {
        var usedByTicket = await _context.Tickets.AnyAsync(t => t.TransactionId == transactionId);
        var usedBySubscription = await _context.Subscriptions.AnyAsync(s => s.TransactionId == transactionId);

        if (usedByTicket || usedBySubscription)
        {
            throw new InvalidOperationException("Transakcija je već iskorištena");
        }
    }
}
