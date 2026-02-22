using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SchedulesController : ControllerBase
{
    private readonly IScheduleService _scheduleService;

    public SchedulesController(IScheduleService scheduleService)
    {
        _scheduleService = scheduleService;
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
            return StatusCode(500, new { message = "An error occurred while creating the schedule", error = ex.Message });
        }
    }

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
            return StatusCode(500, new { message = "An error occurred while updating the schedule", error = ex.Message });
        }
    }

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
            return StatusCode(500, new { message = "An error occurred while deleting the schedule", error = ex.Message });
        }
    }
}
