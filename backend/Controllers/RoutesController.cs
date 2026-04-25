using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

    public RoutesController(IRouteService routeService, INextDepartureService nextDepartureService)
    {
        _routeService = routeService;
        _nextDepartureService = nextDepartureService;
    }

    [HttpGet]
    public async Task<ActionResult<List<RouteDto>>> GetAll([FromQuery] string? search, [FromQuery] bool? isActive)
    {
        var routes = await _routeService.GetAllAsync(search, isActive);
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
        var route = await _routeService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = route.Id }, route);
    }

    [Authorize(Policy = "Administrator")]
    [HttpPut("{id}")]
    public async Task<ActionResult<RouteDto>> Update(int id, [FromBody] UpdateRouteDto dto)
    {
        var route = await _routeService.UpdateAsync(id, dto);
        if (route == null)
        {
            return NotFound();
        }
        return Ok(route);
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
