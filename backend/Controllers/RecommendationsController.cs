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
public class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService _recommendationService;
    private readonly ILogger<RecommendationsController> _logger;

    public RecommendationsController(IRecommendationService recommendationService, ILogger<RecommendationsController> logger)
    {
        _recommendationService = recommendationService;
        _logger = logger;
    }

    [HttpGet("lines")]
    public async Task<ActionResult<List<RecommendedLineDto>>> GetRecommendedLines([FromQuery] int count = 3)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var recommendations = await _recommendationService.GetRecommendedLinesAsync(userId, count);
            return Ok(recommendations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed getting recommendations for user {UserId}", userId);
            return StatusCode(500, new { message = "An error occurred while getting recommendations", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("feedback")]
    public async Task<IActionResult> AddFeedback([FromBody] CreateRecommendationFeedbackDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            await _recommendationService.AddFeedbackAsync(userId, dto.TransportLineId, dto.IsUseful);
            return Ok(new { message = "Feedback saved successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed saving feedback for user {UserId} line {TransportLineId}", userId, dto.TransportLineId);
            return StatusCode(500, new { message = "An error occurred while saving feedback", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpGet("feedback/{transportLineId}")]
    public async Task<ActionResult<bool?>> GetFeedbackStatus(int transportLineId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var feedbackStatus = await _recommendationService.GetFeedbackStatusAsync(userId, transportLineId);
            return Ok(new { feedbackStatus = feedbackStatus });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed getting feedback status for user {UserId} line {TransportLineId}", userId, transportLineId);
            return StatusCode(500, new { message = "An error occurred while getting feedback status", traceId = HttpContext.TraceIdentifier });
        }
    }
}
