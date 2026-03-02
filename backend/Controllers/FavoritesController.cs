using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteService _favoriteService;

    public FavoritesController(IFavoriteService favoriteService)
    {
        _favoriteService = favoriteService;
    }

    [HttpGet("lines")]
    public async Task<ActionResult<List<FavoriteLineDto>>> GetFavoriteLines()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var favorites = await _favoriteService.GetAllAsync(userId);
            return Ok(favorites);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while loading favorite lines", error = ex.Message });
        }
    }

    [HttpGet("lines/{id}")]
    public async Task<ActionResult<FavoriteLineDto>> GetFavoriteLineById(int id)
    {
        var favorite = await _favoriteService.GetByIdAsync(id);
        
        if (favorite == null)
        {
            return NotFound();
        }

        return Ok(favorite);
    }

    [HttpGet("lines/check/{transportLineId}")]
    public async Task<ActionResult<bool>> CheckIsFavorite(int transportLineId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var isFavorite = await _favoriteService.IsFavoriteAsync(userId, transportLineId);
            return Ok(isFavorite);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while checking favorite status", error = ex.Message });
        }
    }

    [HttpPost("lines")]
    public async Task<ActionResult<FavoriteLineDto>> AddFavoriteLine([FromBody] CreateFavoriteLineDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var favorite = await _favoriteService.CreateAsync(userId, dto);
            return CreatedAtAction(nameof(GetFavoriteLineById), new { id = favorite.Id }, favorite);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while adding favorite line", error = ex.Message });
        }
    }

    [HttpDelete("lines/{transportLineId}")]
    public async Task<IActionResult> RemoveFavoriteLine(int transportLineId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized(new { message = "User not authenticated or user ID not found." });
        }

        try
        {
            var deleted = await _favoriteService.DeleteAsync(userId, transportLineId);
            
            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while removing favorite line", error = ex.Message });
        }
    }
}
