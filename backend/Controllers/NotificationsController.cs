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
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(INotificationService notificationService, ILogger<NotificationsController> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    [Authorize(Policy = "Administrator")]
    [HttpGet("metrics")]
    public async Task<ActionResult<NotificationMetricsDto>> GetMetrics()
    {
        var metrics = await _notificationService.GetMetricsAsync();
        return Ok(metrics);
    }

    [Authorize(Policy = "Administrator")]
    [HttpGet]
    public async Task<ActionResult<PagedResultDto<NotificationDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] int? userId = null,
        [FromQuery] string? type = null,
        [FromQuery] bool? isRead = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? search = null)
    {
        var notifications = await _notificationService.GetPagedAsync(
            page, pageSize, userId, type, isRead, isActive, dateFrom, dateTo, search);
        return Ok(notifications);
    }

    [Authorize(Policy = "Administrator")]
    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<NotificationDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] int? userId = null,
        [FromQuery] string? type = null,
        [FromQuery] bool? isRead = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? search = null)
    {
        var notifications = await _notificationService.GetPagedAsync(
            page, pageSize, userId, type, isRead, isActive, dateFrom, dateTo, search);
        return Ok(notifications);
    }

    [Authorize(Policy = "Administrator")]
    [HttpGet("{id}")]
    public async Task<ActionResult<NotificationDto>> GetById(int id)
    {
        var notification = await _notificationService.GetByIdAsync(id);
        
        if (notification == null)
        {
            return NotFound();
        }

        return Ok(notification);
    }

    [Authorize(Policy = "Administrator")]
    [HttpPost]
    public async Task<ActionResult<NotificationDto>> Create([FromBody] CreateNotificationDto dto)
    {
        try
        {
            var notification = await _notificationService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = notification.Id }, notification);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating notification");
            return StatusCode(500, new { message = "An error occurred while creating the notification", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpPut("{id}")]
    public async Task<ActionResult<NotificationDto>> Update(int id, [FromBody] UpdateNotificationDto dto)
    {
        try
        {
            var notification = await _notificationService.UpdateAsync(id, dto);
            
            if (notification == null)
            {
                return NotFound();
            }

            return Ok(notification);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed updating notification {NotificationId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the notification", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(int id)
    {
        var result = await _notificationService.DeleteAsync(id);
        
        if (!result)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpPost("{id}/mark-read")]
    public async Task<ActionResult> MarkAsRead(int id)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        var isAdmin = User.IsInRole("Administrator");
        var result = await _notificationService.MarkAsReadAsync(id, userId, isAdmin);
        
        if (!result)
        {
            return NotFound();
        }

        return Ok(new { message = "Notification marked as read" });
    }

    [HttpGet("my")]
    public async Task<ActionResult<PagedResultDto<NotificationDto>>> GetMyNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool? isRead = null)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        var notifications = await _notificationService.GetPagedAsync(
            page,
            pageSize,
            userId: userId,
            type: null,
            isRead: isRead,
            isActive: true,
            dateFrom: null,
            dateTo: null,
            search: null);
        return Ok(notifications);
    }

    [HttpGet("my/unread-count")]
    public async Task<ActionResult<int>> GetMyUnreadCount()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        var notifications = await _notificationService.GetAllAsync(
            userId: userId,
            isRead: false,
            isActive: true);
        return Ok(notifications.Count);
    }
}
