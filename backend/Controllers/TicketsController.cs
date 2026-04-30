using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;
    private readonly IUserService _userService;
    private readonly ILogger<TicketsController> _logger;

    public TicketsController(ITicketService ticketService, IUserService userService, ILogger<TicketsController> logger)
    {
        _ticketService = ticketService;
        _userService = userService;
        _logger = logger;
    }

    [HttpGet("metrics")]
    public async Task<ActionResult<TicketMetricsDto>> GetMetrics()
    {
        var metrics = await _ticketService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<TicketDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] int? ticketTypeId = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        int? userId = null;
        
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            var isAdmin = User.IsInRole("Administrator");
            if (!isAdmin)
            {
                userId = parsedUserId;
            }
        }

        var result = await _ticketService.GetPagedAsync(page, pageSize, search, status, ticketTypeId, dateFrom, dateTo, userId);
        return Ok(result);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<TicketDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] int? ticketTypeId = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        int? userId = null;

        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            var isAdmin = User.IsInRole("Administrator");
            if (!isAdmin)
            {
                userId = parsedUserId;
            }
        }

        var result = await _ticketService.GetPagedAsync(page, pageSize, search, status, ticketTypeId, dateFrom, dateTo, userId);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TicketDto>> GetById(int id)
    {
        var ticket = await _ticketService.GetByIdAsync(id);
        
        if (ticket == null)
        {
            return NotFound();
        }

        return Ok(ticket);
    }

    [HttpPost("purchase")]
    public async Task<ActionResult<TicketDto>> Purchase([FromBody] PurchaseTicketDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var ticket = await _ticketService.PurchaseAsync(dto, userId);
            return Ok(ticket);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Ticket purchase failed for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while purchasing the ticket", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("{publicId:guid}/validate")]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<TicketValidationResultDto>> Validate(Guid publicId)
    {
        try
        {
            var result = await _ticketService.ValidateAsync(publicId);
            if (string.Equals(result.Status, "NotFound", StringComparison.OrdinalIgnoreCase))
            {
                return NotFound(result);
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Ticket validation failed for publicId {PublicId}", publicId);
            return StatusCode(500, new TicketValidationResultDto
            {
                IsValid = false,
                Status = "Error",
                Message = "Došlo je do greške prilikom validacije karte."
            });
        }
    }
}
