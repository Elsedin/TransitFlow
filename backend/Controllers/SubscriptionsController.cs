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
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;
    private readonly ILogger<SubscriptionsController> _logger;

    public SubscriptionsController(ISubscriptionService subscriptionService, ILogger<SubscriptionsController> logger)
    {
        _subscriptionService = subscriptionService;
        _logger = logger;
    }

    [HttpGet("metrics")]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<SubscriptionMetricsDto>> GetMetrics()
    {
        var metrics = await _subscriptionService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<SubscriptionDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? sortBy = null)
    {
        if (User.IsInRole("Administrator"))
        {
            var subscriptionsAdmin = await _subscriptionService.GetPagedAsync(page, pageSize, search, status, null, dateFrom, dateTo, sortBy);
            return Ok(subscriptionsAdmin);
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        int? userId = null;
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            userId = parsedUserId;
        }

        var subscriptions = await _subscriptionService.GetPagedAsync(page, pageSize, search, status, userId, dateFrom, dateTo, sortBy);
        return Ok(subscriptions);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<SubscriptionDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? sortBy = null)
    {
        if (User.IsInRole("Administrator"))
        {
            var subscriptionsAdmin = await _subscriptionService.GetPagedAsync(page, pageSize, search, status, null, dateFrom, dateTo, sortBy);
            return Ok(subscriptionsAdmin);
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        int? userId = null;
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            userId = parsedUserId;
        }

        var subscriptions = await _subscriptionService.GetPagedAsync(page, pageSize, search, status, userId, dateFrom, dateTo, sortBy);
        return Ok(subscriptions);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SubscriptionDto>> GetById(int id)
    {
        var subscription = await _subscriptionService.GetByIdAsync(id);
        
        if (subscription == null)
        {
            return NotFound();
        }

        return Ok(subscription);
    }

    [HttpPost]
    public async Task<ActionResult<SubscriptionDto>> Create([FromBody] CreateSubscriptionDto dto)
    {
        var isAdmin = User.IsInRole("Administrator");
        
        if (!isAdmin)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var authenticatedUserId))
            {
                return Unauthorized(new { message = "User not authenticated or user ID not found." });
            }
            
            dto.UserId = authenticatedUserId;
        }
        else
        {
            if (dto.UserId <= 0)
            {
                return BadRequest(new { message = "User ID must be provided and valid when creating subscription for another user." });
            }
        }
        
        if (dto.UserId <= 0)
        {
            return BadRequest(new { message = "User ID must be provided and valid." });
        }

        try
        {
            var subscription = await _subscriptionService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = subscription.Id }, subscription);
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
            _logger.LogError(ex, "Failed creating subscription for user {UserId}", dto.UserId);
            return StatusCode(500, new { message = "An error occurred while creating the subscription", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<SubscriptionDto>> Update(int id, [FromBody] UpdateSubscriptionDto dto)
    {
        try
        {
            var subscription = await _subscriptionService.UpdateAsync(id, dto);
            
            if (subscription == null)
            {
                return NotFound();
            }

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
            _logger.LogError(ex, "Failed updating subscription {SubscriptionId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the subscription", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<SubscriptionDto>> Cancel(int id)
    {
        try
        {
            var subscription = await _subscriptionService.CancelAsync(id);
            
            if (subscription == null)
            {
                return NotFound();
            }

            return Ok(subscription);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed cancelling subscription {SubscriptionId}", id);
            return StatusCode(500, new { message = "An error occurred while cancelling the subscription", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _subscriptionService.DeleteAsync(id);
            
            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed deleting subscription {SubscriptionId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the subscription", traceId = HttpContext.TraceIdentifier });
        }
    }
}
