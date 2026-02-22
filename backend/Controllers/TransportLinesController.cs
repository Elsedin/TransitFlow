using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransportLinesController : ControllerBase
{
    private readonly ITransportLineService _transportLineService;

    public TransportLinesController(ITransportLineService transportLineService)
    {
        _transportLineService = transportLineService;
    }

    [HttpGet]
    public async Task<ActionResult<List<TransportLineDto>>> GetAll(
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        var lines = await _transportLineService.GetAllAsync(search, isActive);
        return Ok(lines);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TransportLineDto>> GetById(int id)
    {
        var line = await _transportLineService.GetByIdAsync(id);
        
        if (line == null)
        {
            return NotFound();
        }

        return Ok(line);
    }

    [HttpPost]
    public async Task<ActionResult<TransportLineDto>> Create([FromBody] CreateTransportLineDto dto)
    {
        var line = await _transportLineService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = line.Id }, line);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<TransportLineDto>> Update(int id, [FromBody] UpdateTransportLineDto dto)
    {
        var line = await _transportLineService.UpdateAsync(id, dto);
        
        if (line == null)
        {
            return NotFound();
        }

        return Ok(line);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _transportLineService.DeleteAsync(id);
        
        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}
