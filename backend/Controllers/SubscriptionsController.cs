using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        [FromQuery] int? userId = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? sortBy = null)
    {
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
