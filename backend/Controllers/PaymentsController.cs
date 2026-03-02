using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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

    public PaymentsController(IPaymentService paymentService, ApplicationDbContext context)
    {
        _paymentService = paymentService;
        _context = context;
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
            return StatusCode(500, new { message = "An error occurred while creating payment intent", error = ex.Message });
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
            return StatusCode(500, new { message = "An error occurred while confirming payment", error = ex.Message });
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
            return StatusCode(500, new { message = "An error occurred while creating PayPal order", error = ex.Message });
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
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while capturing PayPal order", error = ex.Message });
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
