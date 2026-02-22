using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public TicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpGet("metrics")]
    public async Task<ActionResult<TicketMetricsDto>> GetMetrics()
    {
        var metrics = await _ticketService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet]
    public async Task<ActionResult<List<TicketDto>>> GetAll(
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] int? ticketTypeId = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null)
    {
        var tickets = await _ticketService.GetAllAsync(search, status, ticketTypeId, dateFrom, dateTo);
        return Ok(tickets);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TicketDto>> GetById(int id)
    {
        var ticket = await _ticketService.GetByIdAsync(id);
        
        if (ticket == null)
        {
            return NotFound();
        }

        return Ok(ticket);
    }
}
