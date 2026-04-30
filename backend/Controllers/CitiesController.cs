using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using City = TransitFlow.API.Models.City;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "Administrator")]
public class CitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CitiesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<CityDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        return await GetPaged(page, pageSize, search, isActive);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<CityDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = _context.Cities
            .Include(c => c.Country)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(c =>
                c.Name.Contains(search) ||
                (c.PostalCode != null && c.PostalCode.Contains(search)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        var total = await query.CountAsync();
        var cities = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = cities.Select(c => new CityDto
        {
            Id = c.Id,
            Name = c.Name,
            PostalCode = c.PostalCode,
            CountryId = c.CountryId,
            CountryName = c.Country?.Name ?? string.Empty,
            IsActive = c.IsActive
        }).ToList();

        return Ok(new PagedResultDto<CityDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CityDto>> GetById(int id)
    {
        var city = await _context.Cities
            .Include(c => c.Country)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (city == null)
        {
            return NotFound();
        }

        var result = new CityDto
        {
            Id = city.Id,
            Name = city.Name,
            PostalCode = city.PostalCode,
            CountryId = city.CountryId,
            CountryName = city.Country?.Name ?? string.Empty,
            IsActive = city.IsActive
        };

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<CityDto>> Create([FromBody] CreateCityDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        if (dto.CountryId.HasValue)
        {
            var countryExists = await _context.Countries.AnyAsync(c => c.Id == dto.CountryId.Value);
            if (!countryExists)
            {
                return BadRequest(new { message = $"Country with ID {dto.CountryId.Value} does not exist" });
            }
        }

        var city = new City
        {
            Name = dto.Name.Trim(),
            PostalCode = string.IsNullOrWhiteSpace(dto.PostalCode) ? null : dto.PostalCode.Trim(),
            CountryId = dto.CountryId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Cities.Add(city);
        await _context.SaveChangesAsync();

        await _context.Entry(city).ReloadAsync();
        await _context.Entry(city).Reference(c => c.Country).LoadAsync();

        var result = new CityDto
        {
            Id = city.Id,
            Name = city.Name,
            PostalCode = city.PostalCode,
            CountryId = city.CountryId,
            CountryName = city.Country?.Name ?? string.Empty,
            IsActive = city.IsActive
        };

        return CreatedAtAction(nameof(GetById), new { id = city.Id }, result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<CityDto>> Update(int id, [FromBody] UpdateCityDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var city = await _context.Cities
            .Include(c => c.Country)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (city == null)
        {
            return NotFound();
        }

        if (dto.CountryId.HasValue)
        {
            var countryExists = await _context.Countries.AnyAsync(c => c.Id == dto.CountryId.Value);
            if (!countryExists)
            {
                return BadRequest(new { message = $"Country with ID {dto.CountryId.Value} does not exist" });
            }
        }

        city.Name = dto.Name.Trim();
        city.PostalCode = string.IsNullOrWhiteSpace(dto.PostalCode) ? null : dto.PostalCode.Trim();
        city.CountryId = dto.CountryId;
        city.IsActive = dto.IsActive;
        city.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        await _context.Entry(city).Reference(c => c.Country).LoadAsync();

        var result = new CityDto
        {
            Id = city.Id,
            Name = city.Name,
            PostalCode = city.PostalCode,
            CountryId = city.CountryId,
            CountryName = city.Country?.Name ?? string.Empty,
            IsActive = city.IsActive
        };

        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var city = await _context.Cities
            .Include(c => c.Stations)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (city == null)
        {
            return NotFound();
        }

        if (city.Stations.Any())
        {
            return BadRequest(new { message = "Cannot delete city that is used in stations" });
        }

        _context.Cities.Remove(city);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
