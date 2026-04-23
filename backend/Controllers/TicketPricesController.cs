using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "Administrator")]
public class TicketPricesController : ControllerBase
{
    private readonly ITicketPriceService _ticketPriceService;
    private readonly ILogger<TicketPricesController> _logger;

    public TicketPricesController(ITicketPriceService ticketPriceService, ILogger<TicketPricesController> logger)
    {
        _ticketPriceService = ticketPriceService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<TicketPriceDto>>> GetAll(
        [FromQuery] int? ticketTypeId = null,
        [FromQuery] int? zoneId = null,
        [FromQuery] bool? isActive = null)
    {
        var ticketPrices = await _ticketPriceService.GetAllAsync(ticketTypeId, zoneId, isActive);
        return Ok(ticketPrices);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TicketPriceDto>> GetById(int id)
    {
        var ticketPrice = await _ticketPriceService.GetByIdAsync(id);
        
        if (ticketPrice == null)
        {
            return NotFound();
        }

        return Ok(ticketPrice);
    }

    [HttpPost]
    public async Task<ActionResult<TicketPriceDto>> Create([FromBody] CreateTicketPriceDto dto)
    {
        try
        {
            var ticketPrice = await _ticketPriceService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = ticketPrice.Id }, ticketPrice);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating ticket price");
            return StatusCode(500, new { message = "An error occurred while creating the ticket price", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<TicketPriceDto>> Update(int id, [FromBody] UpdateTicketPriceDto dto)
    {
        try
        {
            var ticketPrice = await _ticketPriceService.UpdateAsync(id, dto);
            
            if (ticketPrice == null)
            {
                return NotFound();
            }

            return Ok(ticketPrice);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed updating ticket price {TicketPriceId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the ticket price", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _ticketPriceService.DeleteAsync(id);
            
            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed deleting ticket price {TicketPriceId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the ticket price", traceId = HttpContext.TraceIdentifier });
        }
    }
}
