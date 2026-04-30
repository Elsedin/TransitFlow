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
    private readonly ApplicationDbContext _context;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(IPaymentService paymentService, ApplicationDbContext context, ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _context = context;
        _logger = logger;
    }

    [HttpPost("stripe/create-intent")]
    public async Task<ActionResult<PaymentIntentResponse>> CreateStripeIntent([FromBody] CreatePaymentRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var result = await _paymentService.CreateStripePaymentIntentAsync(
                request.Amount,
                request.Currency ?? "bam",
                userId.Value
            );
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating Stripe payment intent for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while creating payment intent", traceId = HttpContext.TraceIdentifier });
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
    public async Task<ActionResult<PayPalOrderResponse>> CreatePayPalOrder([FromBody] CreatePayPalOrderRequest request)
    {
        var userId = await GetUserIdAsync();
        if (userId == null)
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var result = await _paymentService.CreatePayPalOrderAsync(
                request.Amount,
                request.Currency ?? "bam",
                userId.Value
            );
            return Ok(result);
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
