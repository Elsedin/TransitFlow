using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RoutesController : ControllerBase
{
    private readonly IRouteService _routeService;
    private readonly INextDepartureService _nextDepartureService;
    private readonly ILogger<RoutesController> _logger;

    public RoutesController(
        IRouteService routeService,
        INextDepartureService nextDepartureService,
        ILogger<RoutesController> logger)
    {
        _routeService = routeService;
        _nextDepartureService = nextDepartureService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<RouteDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] int? transportLineId = null)
    {
        var routes = await _routeService.GetPagedAsync(page, pageSize, search, isActive, transportLineId);
        return Ok(routes);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<RouteDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] int? transportLineId = null)
    {
        var routes = await _routeService.GetPagedAsync(page, pageSize, search, isActive, transportLineId);
        return Ok(routes);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<RouteDto>> GetById(int id)
    {
        var route = await _routeService.GetByIdAsync(id);
        if (route == null)
        {
            return NotFound();
        }
        return Ok(route);
    }

    [HttpGet("{id}/next-departures")]
    public async Task<ActionResult<List<NextDepartureDto>>> GetNextDepartures(int id, [FromQuery] int count = 3)
    {
        var departures = await _nextDepartureService.GetNextDeparturesAsync(id, count, DateTimeOffset.UtcNow);
        return Ok(departures);
    }

    [Authorize(Policy = "Administrator")]
    [HttpPost]
    public async Task<ActionResult<RouteDto>> Create([FromBody] CreateRouteDto dto)
    {
        try
        {
            var route = await _routeService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = route.Id }, route);
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
            _logger.LogError(ex, "Failed creating route");
            return StatusCode(500, new { message = "An error occurred while creating the route", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpPut("{id}")]
    public async Task<ActionResult<RouteDto>> Update(int id, [FromBody] UpdateRouteDto dto)
    {
        try
        {
            var route = await _routeService.UpdateAsync(id, dto);
            if (route == null)
            {
                return NotFound();
            }
            return Ok(route);
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
            _logger.LogError(ex, "Failed updating route {RouteId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the route", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _routeService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound();
        }
        return NoContent();
    }
}
