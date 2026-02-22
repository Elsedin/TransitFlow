using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Zone = TransitFlow.API.Models.Zone;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ZonesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ZonesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<ZoneDto>>> GetAll([FromQuery] string? search = null, [FromQuery] bool? isActive = null)
    {
        var query = _context.Zones
            .Include(z => z.Stations)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(z => 
                z.Name.Contains(search) || 
                (z.Description != null && z.Description.Contains(search)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(z => z.IsActive == isActive.Value);
        }

        var zones = await query
            .OrderBy(z => z.Name)
            .ToListAsync();

        var result = zones.Select(z => new ZoneDto
        {
            Id = z.Id,
            Name = z.Name,
            Description = z.Description,
            StationCount = z.Stations.Count,
            IsActive = z.IsActive
        }).ToList();

        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ZoneDto>> GetById(int id)
    {
        var zone = await _context.Zones
            .Include(z => z.Stations)
            .FirstOrDefaultAsync(z => z.Id == id);

        if (zone == null)
        {
            return NotFound();
        }

        var result = new ZoneDto
        {
            Id = zone.Id,
            Name = zone.Name,
            Description = zone.Description,
            StationCount = zone.Stations.Count,
            IsActive = zone.IsActive
        };

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<ZoneDto>> Create([FromBody] CreateZoneDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var zone = new Zone
        {
            Name = dto.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Zones.Add(zone);
        await _context.SaveChangesAsync();

        await _context.Entry(zone).ReloadAsync();
        await _context.Entry(zone).Collection(z => z.Stations).LoadAsync();

        var result = new ZoneDto
        {
            Id = zone.Id,
            Name = zone.Name,
            Description = zone.Description,
            StationCount = zone.Stations.Count,
            IsActive = zone.IsActive
        };

        return CreatedAtAction(nameof(GetById), new { id = zone.Id }, result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ZoneDto>> Update(int id, [FromBody] UpdateZoneDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var zone = await _context.Zones
            .Include(z => z.Stations)
            .FirstOrDefaultAsync(z => z.Id == id);

        if (zone == null)
        {
            return NotFound();
        }

        zone.Name = dto.Name.Trim();
        zone.Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim();
        zone.IsActive = dto.IsActive;
        zone.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var result = new ZoneDto
        {
            Id = zone.Id,
            Name = zone.Name,
            Description = zone.Description,
            StationCount = zone.Stations.Count,
            IsActive = zone.IsActive
        };

        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var zone = await _context.Zones
            .Include(z => z.Stations)
            .Include(z => z.TicketPrices)
            .Include(z => z.Tickets)
            .FirstOrDefaultAsync(z => z.Id == id);

        if (zone == null)
        {
            return NotFound();
        }

        if (zone.Stations.Any() || zone.TicketPrices.Any() || zone.Tickets.Any())
        {
            return BadRequest(new { message = "Cannot delete zone that is used in stations, ticket prices, or tickets" });
        }

        _context.Zones.Remove(zone);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
