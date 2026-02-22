using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TicketType = TransitFlow.API.Models.TicketType;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TicketTypesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TicketTypesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<TicketTypeDto>>> GetAll([FromQuery] string? search = null, [FromQuery] bool? isActive = null)
    {
        var query = _context.TicketTypes.AsQueryable();

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
            .Select(t => new TicketTypeDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                ValidityDays = t.ValidityDays,
                IsActive = t.IsActive
            })
            .ToListAsync();

        return Ok(types);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TicketTypeDto>> GetById(int id)
    {
        var ticketType = await _context.TicketTypes.FindAsync(id);

        if (ticketType == null)
        {
            return NotFound();
        }

        var result = new TicketTypeDto
        {
            Id = ticketType.Id,
            Name = ticketType.Name,
            Description = ticketType.Description,
            ValidityDays = ticketType.ValidityDays,
            IsActive = ticketType.IsActive
        };

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<TicketTypeDto>> Create([FromBody] CreateTicketTypeDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var ticketType = new TicketType
        {
            Name = dto.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            ValidityDays = dto.ValidityDays,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.TicketTypes.Add(ticketType);
        await _context.SaveChangesAsync();

        var result = new TicketTypeDto
        {
            Id = ticketType.Id,
            Name = ticketType.Name,
            Description = ticketType.Description,
            ValidityDays = ticketType.ValidityDays,
            IsActive = ticketType.IsActive
        };

        return CreatedAtAction(nameof(GetById), new { id = ticketType.Id }, result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<TicketTypeDto>> Update(int id, [FromBody] UpdateTicketTypeDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var ticketType = await _context.TicketTypes.FindAsync(id);

        if (ticketType == null)
        {
            return NotFound();
        }

        ticketType.Name = dto.Name.Trim();
        ticketType.Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim();
        ticketType.ValidityDays = dto.ValidityDays;
        ticketType.IsActive = dto.IsActive;
        ticketType.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var result = new TicketTypeDto
        {
            Id = ticketType.Id,
            Name = ticketType.Name,
            Description = ticketType.Description,
            ValidityDays = ticketType.ValidityDays,
            IsActive = ticketType.IsActive
        };

        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ticketType = await _context.TicketTypes
            .Include(t => t.Tickets)
            .Include(t => t.TicketPrices)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (ticketType == null)
        {
            return NotFound();
        }

        if (ticketType.Tickets.Any() || ticketType.TicketPrices.Any())
        {
            return BadRequest(new { message = "Cannot delete ticket type that is used in tickets or ticket prices" });
        }

        _context.TicketTypes.Remove(ticketType);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
