using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransportLinesController : ControllerBase
{
    private readonly ITransportLineService _transportLineService;
    private readonly ILogger<TransportLinesController> _logger;

    public TransportLinesController(ITransportLineService transportLineService, ILogger<TransportLinesController> logger)
    {
        _transportLineService = transportLineService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<TransportLineDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        var lines = await _transportLineService.GetPagedAsync(page, pageSize, search, isActive);
        return Ok(lines);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<TransportLineDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        var lines = await _transportLineService.GetPagedAsync(page, pageSize, search, isActive);
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

    [Authorize(Policy = "Administrator")]
    [HttpPost]
    public async Task<ActionResult<TransportLineDto>> Create([FromBody] CreateTransportLineDto dto)
    {
        try
        {
            var line = await _transportLineService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = line.Id }, line);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating transport line");
            return StatusCode(500, new { message = "An error occurred while creating the transport line", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpPut("{id}")]
    public async Task<ActionResult<TransportLineDto>> Update(int id, [FromBody] UpdateTransportLineDto dto)
    {
        try
        {
            var line = await _transportLineService.UpdateAsync(id, dto);
        
            if (line == null)
            {
                return NotFound();
            }

            return Ok(line);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed updating transport line {TransportLineId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the transport line", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
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
