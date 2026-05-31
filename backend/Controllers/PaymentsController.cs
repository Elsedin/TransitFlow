using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly IPaymentPricingService _paymentPricingService;
    private readonly IPaymentFulfillmentService _paymentFulfillmentService;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(
        IPaymentService paymentService,
        IPaymentPricingService paymentPricingService,
        IPaymentFulfillmentService paymentFulfillmentService,
        ApplicationDbContext context,
        ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _paymentPricingService = paymentPricingService;
        _paymentFulfillmentService = paymentFulfillmentService;
        _context = context;
        _logger = logger;
    }

    [HttpPost("stripe/create-intent")]
    public async Task<ActionResult<PaymentIntentResponse>> CreateStripeIntent([FromBody] CreatePaymentIntentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var amount = await ResolvePaymentAmountAsync(userId.Value, request);
            if (amount <= 0)
            {
                return BadRequest(new { message = "No payment required for this purchase" });
            }

            var result = await _paymentService.CreateStripePaymentIntentAsync(
                amount,
                request.Currency ?? "bam",
                userId.Value
            );
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating Stripe payment intent for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while creating payment intent", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("stripe/finalize-ticket")]
    public async Task<ActionResult<TicketDto>> FinalizeStripeTicket([FromBody] FinalizeTicketPaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var ticket = await _paymentFulfillmentService.FinalizeStripeTicketAsync(userId.Value, request);
            return Ok(ticket);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed finalizing Stripe ticket purchase for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while finalizing ticket purchase", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("stripe/finalize-subscription")]
    public async Task<ActionResult<SubscriptionDto>> FinalizeStripeSubscription([FromBody] FinalizeSubscriptionPaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var subscription = await _paymentFulfillmentService.FinalizeStripeSubscriptionAsync(userId.Value, request);
            return Ok(subscription);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed finalizing Stripe subscription purchase for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while finalizing subscription purchase", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("stripe/confirm")]
    public async Task<ActionResult<PaymentResult>> ConfirmStripePayment([FromBody] ConfirmPaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var result = await _paymentService.ConfirmStripePaymentAsync(request.PaymentIntentId, userId.Value);
            
            if (!result.Success)
            {
                return BadRequest(result);
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed confirming Stripe payment for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while confirming payment", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("paypal/create-order")]
    public async Task<ActionResult<PayPalOrderResponse>> CreatePayPalOrder([FromBody] CreatePaymentIntentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var amount = await ResolvePaymentAmountAsync(userId.Value, request);
            if (amount <= 0)
            {
                return BadRequest(new { message = "No payment required for this purchase" });
            }

            var result = await _paymentService.CreatePayPalOrderAsync(
                amount,
                request.Currency ?? "bam",
                userId.Value
            );
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating PayPal order for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while creating PayPal order", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("paypal/finalize-ticket")]
    public async Task<ActionResult<TicketDto>> FinalizePayPalTicket([FromBody] FinalizePayPalTicketPaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var ticket = await _paymentFulfillmentService.FinalizePayPalTicketAsync(userId.Value, request);
            return Ok(ticket);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed finalizing PayPal ticket purchase for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while finalizing ticket purchase", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("paypal/finalize-subscription")]
    public async Task<ActionResult<SubscriptionDto>> FinalizePayPalSubscription([FromBody] FinalizePayPalSubscriptionPaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var subscription = await _paymentFulfillmentService.FinalizePayPalSubscriptionAsync(userId.Value, request);
            return Ok(subscription);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed finalizing PayPal subscription purchase for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while finalizing subscription purchase", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpGet("recoverable")]
    public async Task<ActionResult<List<RecoverableTransactionDto>>> GetRecoverableTransactions()
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        var items = await _paymentFulfillmentService.GetRecoverableTransactionsAsync(userId.Value);
        return Ok(items);
    }

    [HttpPost("recover")]
    public async Task<ActionResult<RecoverPurchaseResultDto>> RecoverPurchase([FromBody] RecoverPurchaseRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var result = await _paymentFulfillmentService.RecoverPurchaseAsync(userId.Value, request);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed recovering purchase for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while recovering purchase", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("paypal/capture")]
    public async Task<ActionResult<PaymentResult>> CapturePayPalOrder([FromBody] CapturePayPalOrderRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var result = await _paymentService.CapturePayPalOrderAsync(request.OrderId, userId.Value);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            var msg = ex.Message;
            if (msg.Contains("COMPLIANCE_VIOLATION", StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new
                {
                    message = "PayPal Sandbox je odbio transakciju (COMPLIANCE_VIOLATION). Pokušajte ponovo ili koristite Kartica (Stripe)."
                });
            }
            return BadRequest(new { message = msg });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed capturing PayPal order for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while capturing PayPal order", traceId = HttpContext.TraceIdentifier });
        }
    }

    private async Task<decimal> ResolvePaymentAmountAsync(int userId, CreatePaymentIntentRequest request)
    {
        var purchaseType = (request.PurchaseType ?? string.Empty).Trim().ToLowerInvariant();

        return purchaseType switch
        {
            "ticket" => await ResolveTicketAmountAsync(userId, request),
            "subscription" => await ResolveSubscriptionAmountAsync(request),
            _ => throw new ArgumentException("Invalid purchase type")
        };
    }

    private async Task<decimal> ResolveTicketAmountAsync(int userId, CreatePaymentIntentRequest request)
    {
        if (!request.TicketTypeId.HasValue || !request.RouteId.HasValue || !request.ZoneId.HasValue || !request.ValidFrom.HasValue)
        {
            throw new ArgumentException("Ticket purchase requires ticketTypeId, routeId, zoneId and validFrom");
        }

        return await _paymentPricingService.CalculateTicketAmountAsync(
            userId,
            request.TicketTypeId.Value,
            request.ZoneId.Value,
            request.ValidFrom.Value);
    }

    private async Task<decimal> ResolveSubscriptionAmountAsync(CreatePaymentIntentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.PackageKey))
        {
            throw new ArgumentException("Subscription purchase requires packageKey");
        }

        return await _paymentPricingService.CalculateSubscriptionAmountAsync(request.PackageKey);
    }

    private async Task<int?> GetUserIdAsync()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var userId))
        {
            return userId;
        }

        var usernameClaim = User.FindFirst(ClaimTypes.Name);
        if (usernameClaim != null)
        {
            var username = usernameClaim.Value;
            if (!string.IsNullOrEmpty(username))
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Username == username && u.IsActive);
                if (user != null)
                {
                    return user.Id;
                }
            }
        }

        return null;
    }
}
