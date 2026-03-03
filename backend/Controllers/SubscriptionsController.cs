using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

    public SubscriptionsController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    [HttpGet("metrics")]
    public async Task<ActionResult<SubscriptionMetricsDto>> GetMetrics()
    {
        var metrics = await _subscriptionService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet]
    public async Task<ActionResult<List<SubscriptionDto>>> GetAll(
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? sortBy = null)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        int? userId = null;
        if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            userId = parsedUserId;
        }

        var subscriptions = await _subscriptionService.GetAllAsync(search, status, userId, dateFrom, dateTo, sortBy);
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
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while creating the subscription", error = ex.Message });
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
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while updating the subscription", error = ex.Message });
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
            return StatusCode(500, new { message = "An error occurred while cancelling the subscription", error = ex.Message });
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
            return StatusCode(500, new { message = "An error occurred while deleting the subscription", error = ex.Message });
        }
    }
}
