using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RefundRequestsController : ControllerBase
{
    private readonly IRefundRequestService _service;
    private readonly ILogger<RefundRequestsController> _logger;

    public RefundRequestsController(IRefundRequestService service, ILogger<RefundRequestsController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult<RefundRequestDto>> Create([FromBody] CreateRefundRequestDto dto)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(new { message = "Not authenticated" });
        }
        try
        {
            var created = await _service.CreateAsync(userId, dto);
            return Ok(created);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund request create failed for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while creating refund request", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpGet("my")]
    public async Task<ActionResult<List<RefundRequestDto>>> GetMy()
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(new { message = "Not authenticated" });
        }
        var items = await _service.GetMyAsync(userId);
        return Ok(items);
    }

    [HttpGet]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<List<RefundRequestDto>>> GetAll([FromQuery] string? status = null)
    {
        var items = await _service.GetAllAsync(status);
        return Ok(items);
    }

    [HttpPost("{id:int}/approve")]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<RefundRequestDto>> Approve(int id, [FromBody] ResolveRefundRequestDto dto)
    {
        if (!TryGetUserId(out var adminId))
        {
            return Unauthorized(new { message = "Not authenticated" });
        }
        try
        {
            var result = await _service.ApproveAsync(adminId, id, dto);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund request approve failed for request {RequestId} by admin {AdminId}", id, adminId);
            return StatusCode(500, new { message = "An error occurred while approving refund request", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("{id:int}/reject")]
    [Authorize(Roles = "Administrator")]
    public async Task<ActionResult<RefundRequestDto>> Reject(int id, [FromBody] ResolveRefundRequestDto dto)
    {
        if (!TryGetUserId(out var adminId))
        {
            return Unauthorized(new { message = "Not authenticated" });
        }
        try
        {
            var result = await _service.RejectAsync(adminId, id, dto);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund request reject failed for request {RequestId} by admin {AdminId}", id, adminId);
            return StatusCode(500, new { message = "An error occurred while rejecting refund request", traceId = HttpContext.TraceIdentifier });
        }
    }

    private bool TryGetUserId(out int id)
    {
        id = 0;

        var candidates = new[]
        {
            ClaimTypes.NameIdentifier,
            "sub",
            "id",
            "userId"
        };

        foreach (var type in candidates)
        {
            var claim = User.FindFirst(type);
            if (claim != null && int.TryParse(claim.Value, out var parsed))
            {
                id = parsed;
                return true;
            }
        }

        return false;
    }
}

