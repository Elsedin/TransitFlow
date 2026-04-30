using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Administrator")]
public class CountriesController : ControllerBase
{
    private readonly ICountryService _service;
    private readonly ILogger<CountriesController> _logger;

    public CountriesController(ICountryService service, ILogger<CountriesController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<CountryDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        var items = await _service.GetPagedAsync(page, pageSize, search, isActive);
        return Ok(items);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<CountryDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        var items = await _service.GetPagedAsync(page, pageSize, search, isActive);
        return Ok(items);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<CountryDto>> GetById(int id)
    {
        var item = await _service.GetByIdAsync(id);
        return item == null ? NotFound() : Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<CountryDto>> Create([FromBody] CreateCountryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        try
        {
            var created = await _service.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed creating country");
            return StatusCode(500, new { message = "An error occurred while creating the country", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<CountryDto>> Update(int id, [FromBody] UpdateCountryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        try
        {
            var updated = await _service.UpdateAsync(id, dto);
            return updated == null ? NotFound() : Ok(updated);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed updating country {CountryId}", id);
            return StatusCode(500, new { message = "An error occurred while updating the country", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed deleting country {CountryId}", id);
            return StatusCode(500, new { message = "An error occurred while deleting the country", traceId = HttpContext.TraceIdentifier });
        }
    }
}

