using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        var response = await _authService.LoginAsync(request);
        
        if (response == null)
        {
            return Unauthorized(new { message = "Invalid username or password" });
        }

        return Ok(response);
    }

    [HttpPost("user/login")]
    public async Task<ActionResult<LoginResponse>> UserLogin([FromBody] LoginRequest request)
    {
        var response = await _authService.UserLoginAsync(request);
        
        if (response == null)
        {
            return Unauthorized(new { message = "Invalid username or password" });
        }

        return Ok(response);
    }

    [HttpPost("user/register")]
    public async Task<ActionResult<RegisterResponse>> Register([FromBody] RegisterRequest request)
    {
        try
        {
            var response = await _authService.RegisterAsync(request);
            return Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Registration failed");
            return StatusCode(500, new { message = "An error occurred during registration", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("user/change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new
            {
                type = "about:blank",
                title = "Validation failed",
                status = StatusCodes.Status400BadRequest,
                message = "Podaci nisu validni",
                errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? "Invalid value" : e.ErrorMessage).ToArray()),
                traceId = HttpContext.TraceIdentifier
            });
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            await _authService.ChangeUserPasswordAsync(userId, dto);
            return Ok(new { message = "Lozinka je uspješno promijenjena" });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Change password failed for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while changing the password", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("user/forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new
            {
                type = "about:blank",
                title = "Validation failed",
                status = StatusCodes.Status400BadRequest,
                message = "Podaci nisu validni",
                errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? "Invalid value" : e.ErrorMessage).ToArray()),
                traceId = HttpContext.TraceIdentifier
            });
        }

        try
        {
            await _authService.RequestPasswordResetAsync(dto);
            return Ok(new
            {
                message = "Ako postoji račun sa tom email adresom, poslat ćemo vam kod za reset lozinke."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Forgot password failed for email {Email}", dto.Email);
            return StatusCode(500, new { message = "An error occurred while processing the request", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("user/reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new
            {
                type = "about:blank",
                title = "Validation failed",
                status = StatusCodes.Status400BadRequest,
                message = "Podaci nisu validni",
                errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? "Invalid value" : e.ErrorMessage).ToArray()),
                traceId = HttpContext.TraceIdentifier
            });
        }

        try
        {
            await _authService.ResetPasswordAsync(dto);
            return Ok(new { message = "Lozinka je uspješno resetovana. Možete se prijaviti." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reset password failed for email {Email}", dto.Email);
            return StatusCode(500, new { message = "An error occurred while resetting the password", traceId = HttpContext.TraceIdentifier });
        }
    }
}
