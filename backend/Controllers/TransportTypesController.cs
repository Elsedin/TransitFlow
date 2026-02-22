using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransportType = TransitFlow.API.Models.TransportType;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransportTypesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TransportTypesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<TransportTypeDto>>> GetAll([FromQuery] string? search = null, [FromQuery] bool? isActive = null)
    {
        var query = _context.TransportTypes.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(t => 
                t.Name.Contains(search) || 
                (t.Description != null && t.Description.Contains(search)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(t => t.IsActive == isActive.Value);
        }

        var types = await query
            .OrderBy(t => t.Name)
            .Select(t => new TransportTypeDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                IsActive = t.IsActive
            })
            .ToListAsync();

        return Ok(types);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TransportTypeDto>> GetById(int id)
    {
        var transportType = await _context.TransportTypes.FindAsync(id);

        if (transportType == null)
        {
            return NotFound();
        }

        var result = new TransportTypeDto
        {
            Id = transportType.Id,
            Name = transportType.Name,
            Description = transportType.Description,
            IsActive = transportType.IsActive
        };

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<TransportTypeDto>> Create([FromBody] CreateTransportTypeDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var transportType = new TransportType
        {
            Name = dto.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.TransportTypes.Add(transportType);
        await _context.SaveChangesAsync();

        var result = new TransportTypeDto
        {
            Id = transportType.Id,
            Name = transportType.Name,
            Description = transportType.Description,
            IsActive = transportType.IsActive
        };

        return CreatedAtAction(nameof(GetById), new { id = transportType.Id }, result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<TransportTypeDto>> Update(int id, [FromBody] UpdateTransportTypeDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var transportType = await _context.TransportTypes.FindAsync(id);

        if (transportType == null)
        {
            return NotFound();
        }

        transportType.Name = dto.Name.Trim();
        transportType.Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim();
        transportType.IsActive = dto.IsActive;
        transportType.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var result = new TransportTypeDto
        {
            Id = transportType.Id,
            Name = transportType.Name,
            Description = transportType.Description,
            IsActive = transportType.IsActive
        };

        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var transportType = await _context.TransportTypes
            .Include(t => t.TransportLines)
            .Include(t => t.Vehicles)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (transportType == null)
        {
            return NotFound();
        }

        if (transportType.TransportLines.Any() || transportType.Vehicles.Any())
        {
            return BadRequest(new { message = "Cannot delete transport type that is used in transport lines or vehicles" });
        }

        _context.TransportTypes.Remove(transportType);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
