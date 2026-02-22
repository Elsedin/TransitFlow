using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Station = TransitFlow.API.Models.Station;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class StationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public StationsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<StationDto>>> GetAll([FromQuery] string? search, [FromQuery] bool? isActive = null)
    {
        var query = _context.Stations
            .Include(s => s.City)
            .Include(s => s.Zone)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(s => 
                s.Name.Contains(search) || 
                (s.Address != null && s.Address.Contains(search)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(s => s.IsActive == isActive.Value);
        }

        var stations = await query
            .OrderBy(s => s.Name)
            .ToListAsync();

        var result = stations.Select(s => new StationDto
        {
            Id = s.Id,
            Name = s.Name,
            Address = s.Address,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            CityId = s.CityId,
            CityName = s.City?.Name ?? string.Empty,
            ZoneId = s.ZoneId,
            ZoneName = s.Zone?.Name ?? string.Empty,
            IsActive = s.IsActive
        }).ToList();

        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<StationDto>> GetById(int id)
    {
        var station = await _context.Stations
            .Include(s => s.City)
            .Include(s => s.Zone)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (station == null)
        {
            return NotFound();
        }

        var result = new StationDto
        {
            Id = station.Id,
            Name = station.Name,
            Address = station.Address,
            Latitude = station.Latitude,
            Longitude = station.Longitude,
            CityId = station.CityId,
            CityName = station.City?.Name ?? string.Empty,
            ZoneId = station.ZoneId,
            ZoneName = station.Zone?.Name ?? string.Empty,
            IsActive = station.IsActive
        };

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<StationDto>> Create([FromBody] CreateStationDto dto)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new { message = "Invalid request data", errors = ModelState });
            }

            if (dto == null)
            {
                return BadRequest(new { message = "Request body is required" });
            }

            if (string.IsNullOrWhiteSpace(dto.Name))
            {
                return BadRequest(new { message = "Station name is required" });
            }

            if (dto.CityId <= 0)
            {
                return BadRequest(new { message = "Valid City ID is required" });
            }

            if (dto.ZoneId <= 0)
            {
                return BadRequest(new { message = "Valid Zone ID is required" });
            }

            if (dto.Latitude.HasValue && (dto.Latitude.Value < -90 || dto.Latitude.Value > 90))
            {
                return BadRequest(new { message = "Latitude must be between -90 and 90" });
            }

            if (dto.Longitude.HasValue && (dto.Longitude.Value < -180 || dto.Longitude.Value > 180))
            {
                return BadRequest(new { message = "Longitude must be between -180 and 180" });
            }

            var city = await _context.Cities.FirstOrDefaultAsync(c => c.Id == dto.CityId);
            if (city == null)
            {
                return BadRequest(new { message = $"City with ID {dto.CityId} does not exist" });
            }

            var zone = await _context.Zones.FirstOrDefaultAsync(z => z.Id == dto.ZoneId);
            if (zone == null)
            {
                return BadRequest(new { message = $"Zone with ID {dto.ZoneId} does not exist" });
            }

            decimal? latitude = null;
            decimal? longitude = null;

            if (dto.Latitude.HasValue)
            {
                try
                {
                    var latValue = Math.Round((double)dto.Latitude.Value, 8, MidpointRounding.AwayFromZero);
                    latitude = new decimal(latValue);
                }
                catch (OverflowException)
                {
                    return BadRequest(new { message = "Latitude value is too large" });
                }
                catch (Exception ex)
                {
                    return BadRequest(new { message = $"Invalid latitude format: {ex.Message}" });
                }
            }

            if (dto.Longitude.HasValue)
            {
                try
                {
                    var lonValue = Math.Round((double)dto.Longitude.Value, 8, MidpointRounding.AwayFromZero);
                    longitude = new decimal(lonValue);
                }
                catch (OverflowException)
                {
                    return BadRequest(new { message = "Longitude value is too large" });
                }
                catch (Exception ex)
                {
                    return BadRequest(new { message = $"Invalid longitude format: {ex.Message}" });
                }
            }

            var station = new Station
            {
                Name = dto.Name.Trim(),
                Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim(),
                Latitude = latitude,
                Longitude = longitude,
                CityId = dto.CityId,
                ZoneId = dto.ZoneId,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Stations.Add(station);
            await _context.SaveChangesAsync();

            await _context.Entry(station).ReloadAsync();
            
            var createdStation = await _context.Stations
                .Include(s => s.City)
                .Include(s => s.Zone)
                .FirstOrDefaultAsync(s => s.Id == station.Id);

            if (createdStation == null)
            {
                return StatusCode(500, new { message = "Station was created but could not be retrieved" });
            }

            var result = new StationDto
            {
                Id = createdStation.Id,
                Name = createdStation.Name,
                Address = createdStation.Address,
                Latitude = createdStation.Latitude,
                Longitude = createdStation.Longitude,
                CityId = createdStation.CityId,
                CityName = createdStation.City?.Name ?? string.Empty,
                ZoneId = createdStation.ZoneId,
                ZoneName = createdStation.Zone?.Name ?? string.Empty,
                IsActive = createdStation.IsActive
            };

            return CreatedAtAction(nameof(GetById), new { id = station.Id }, result);
        }
        catch (DbUpdateException dbEx)
        {
            var errorMessage = dbEx.InnerException?.Message ?? dbEx.Message;
            Console.WriteLine($"[StationsController] Database error: {errorMessage}");
            Console.WriteLine($"[StationsController] Stack trace: {dbEx.StackTrace}");
            
            if (errorMessage.Contains("FK_Stations_Cities") || errorMessage.Contains("CityId"))
            {
                return BadRequest(new { message = "Invalid City ID. The city does not exist or is inactive." });
            }
            
            if (errorMessage.Contains("FK_Stations_Zones") || errorMessage.Contains("ZoneId"))
            {
                return BadRequest(new { message = "Invalid Zone ID. The zone does not exist or is inactive." });
            }
            
            return StatusCode(500, new { message = "Database error occurred while creating the station", error = errorMessage });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[StationsController] Error: {ex.Message}");
            Console.WriteLine($"[StationsController] Stack trace: {ex.StackTrace}");
            return StatusCode(500, new { message = "An error occurred while creating the station", error = ex.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<StationDto>> Update(int id, [FromBody] UpdateStationDto dto)
    {
        try
        {
            var station = await _context.Stations.FindAsync(id);
            if (station == null)
            {
                return NotFound();
            }

            var cityExists = await _context.Cities.AnyAsync(c => c.Id == dto.CityId);
            if (!cityExists)
            {
                return BadRequest(new { message = $"City with ID {dto.CityId} does not exist" });
            }

            var zoneExists = await _context.Zones.AnyAsync(z => z.Id == dto.ZoneId);
            if (!zoneExists)
            {
                return BadRequest(new { message = $"Zone with ID {dto.ZoneId} does not exist" });
            }

            station.Name = dto.Name.Trim();
            station.Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim();
            
            if (dto.Latitude.HasValue)
            {
                var latValue = Math.Round((double)dto.Latitude.Value, 8, MidpointRounding.AwayFromZero);
                station.Latitude = new decimal(latValue);
            }
            else
            {
                station.Latitude = null;
            }
            
            if (dto.Longitude.HasValue)
            {
                var lonValue = Math.Round((double)dto.Longitude.Value, 8, MidpointRounding.AwayFromZero);
                station.Longitude = new decimal(lonValue);
            }
            else
            {
                station.Longitude = null;
            }
            station.CityId = dto.CityId;
            station.ZoneId = dto.ZoneId;
            station.IsActive = dto.IsActive;
            station.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return await GetById(station.Id);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred while updating the station", error = ex.Message });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var station = await _context.Stations
            .Include(s => s.RouteStations)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (station == null)
        {
            return NotFound();
        }

        if (station.RouteStations.Any())
        {
            return BadRequest(new { message = "Cannot delete station that is used in routes" });
        }

        _context.Stations.Remove(station);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
