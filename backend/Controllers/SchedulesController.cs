using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SchedulesController : ControllerBase
{
    private readonly IScheduleService _scheduleService;
    private readonly ILogger<SchedulesController> _logger;

    public SchedulesController(IScheduleService scheduleService, ILogger<SchedulesController> logger)
    {
        _scheduleService = scheduleService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<ScheduleDto>>> GetAll(
        [FromQuery] int? routeId = null,
        [FromQuery] int? vehicleId = null,
        [FromQuery] int? dayOfWeek = null,
        [FromQuery] bool? isActive = null)
    {
        var schedules = await _scheduleService.GetAllAsync(routeId, vehicleId, dayOfWeek, isActive);
        return Ok(schedules);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ScheduleDto>> GetById(int id)
    {
        var schedule = await _scheduleService.GetByIdAsync(id);
        
        if (schedule == null)
        {
            return NotFound();
        }

        return Ok(schedule);
    }

    [Authorize(Policy = "Administrator")]
    [HttpPost]
    public async Task<ActionResult<ScheduleDto>> Create([FromBody] CreateScheduleDto dto)
    {
        try
        {
            var schedule = await _scheduleService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = schedule.Id }, schedule);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating schedule");
            return StatusCode(500, new { message = "An error occurred while creating the schedule", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpPut("{id}")]
    public async Task<ActionResult<ScheduleDto>> Update(int id, [FromBody] UpdateScheduleDto dto)
    {
        try
        {
            var schedule = await _scheduleService.UpdateAsync(id, dto);
            
            if (schedule == null)
            {
                return NotFound();
            }

            return Ok(schedule);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed updating schedule {ScheduleId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the schedule", traceId = HttpContext.TraceIdentifier });
        }
    }

    [Authorize(Policy = "Administrator")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _scheduleService.DeleteAsync(id);
            
            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed deleting schedule {ScheduleId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the schedule", traceId = HttpContext.TraceIdentifier });
        }
    }
}
