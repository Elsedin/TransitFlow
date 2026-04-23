using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
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
    public async Task<ActionResult<List<NotificationDto>>> GetAll(
        [FromQuery] int? userId = null,
        [FromQuery] string? type = null,
        [FromQuery] bool? isRead = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? search = null)
    {
        var notifications = await _notificationService.GetAllAsync(
            userId, type, isRead, isActive, dateFrom, dateTo, search);
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
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
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
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
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
        var result = await _notificationService.MarkAsReadAsync(id);
        
        if (!result)
        {
            return NotFound();
        }

        return Ok(new { message = "Notification marked as read" });
    }

    [HttpGet("my")]
    public async Task<ActionResult<List<NotificationDto>>> GetMyNotifications(
        [FromQuery] bool? isRead = null)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        var notifications = await _notificationService.GetAllAsync(
            userId: userId,
            isRead: isRead,
            isActive: true);
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
