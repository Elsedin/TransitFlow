using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Schedule = TransitFlow.API.Models.Schedule;

namespace TransitFlow.API.Services;

public class ScheduleService : IScheduleService
{
    private readonly ApplicationDbContext _context;

    public ScheduleService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<ScheduleDto>> GetAllAsync(int? routeId = null, int? vehicleId = null, int? dayOfWeek = null, bool? isActive = null)
    {
        var query = _context.Schedules
            .Include(s => s.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(s => s.Vehicle)
            .AsQueryable();

        if (routeId.HasValue)
        {
            query = query.Where(s => s.RouteId == routeId.Value);
        }

        if (vehicleId.HasValue)
        {
            query = query.Where(s => s.VehicleId == vehicleId.Value);
        }

        if (dayOfWeek.HasValue)
        {
            query = query.Where(s => (int)s.DayOfWeek == dayOfWeek.Value);
        }

        if (isActive.HasValue)
        {
            query = query.Where(s => s.IsActive == isActive.Value);
        }

        var schedules = await query
            .OrderBy(s => s.DayOfWeek)
            .ThenBy(s => s.DepartureTime)
            .ToListAsync();

        return schedules.Select(s => new ScheduleDto
        {
            Id = s.Id,
            RouteId = s.RouteId,
            RouteName = s.Route != null 
                ? $"{s.Route.TransportLine?.LineNumber ?? ""} - {s.Route.Origin} - {s.Route.Destination}"
                : string.Empty,
            RouteOrigin = s.Route?.Origin ?? string.Empty,
            RouteDestination = s.Route?.Destination ?? string.Empty,
            VehicleId = s.VehicleId,
            VehicleLicensePlate = s.Vehicle?.LicensePlate ?? string.Empty,
            DepartureTime = s.DepartureTime.ToString("HH:mm"),
            ArrivalTime = s.ArrivalTime.ToString("HH:mm"),
            DayOfWeek = (int)s.DayOfWeek,
            DayOfWeekName = GetDayOfWeekName(s.DayOfWeek),
            IsActive = s.IsActive
        }).ToList();
    }

    public async Task<ScheduleDto?> GetByIdAsync(int id)
    {
        var schedule = await _context.Schedules
            .Include(s => s.Route)
                .ThenInclude(r => r!.TransportLine)
            .Include(s => s.Vehicle)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (schedule == null)
            return null;

        return new ScheduleDto
        {
            Id = schedule.Id,
            RouteId = schedule.RouteId,
            RouteName = schedule.Route != null 
                ? $"{schedule.Route.TransportLine?.LineNumber ?? ""} - {schedule.Route.Origin} - {schedule.Route.Destination}"
                : string.Empty,
            RouteOrigin = schedule.Route?.Origin ?? string.Empty,
            RouteDestination = schedule.Route?.Destination ?? string.Empty,
            VehicleId = schedule.VehicleId,
            VehicleLicensePlate = schedule.Vehicle?.LicensePlate ?? string.Empty,
            DepartureTime = schedule.DepartureTime.ToString("HH:mm"),
            ArrivalTime = schedule.ArrivalTime.ToString("HH:mm"),
            DayOfWeek = (int)schedule.DayOfWeek,
            DayOfWeekName = GetDayOfWeekName(schedule.DayOfWeek),
            IsActive = schedule.IsActive
        };
    }

    public async Task<ScheduleDto> CreateAsync(CreateScheduleDto dto)
    {
        if (!TimeOnly.TryParse(dto.DepartureTime, out var departureTime))
        {
            throw new ArgumentException("Invalid departure time format");
        }

        if (!TimeOnly.TryParse(dto.ArrivalTime, out var arrivalTime))
        {
            throw new ArgumentException("Invalid arrival time format");
        }

        if (dto.DayOfWeek < 0 || dto.DayOfWeek > 6)
        {
            throw new ArgumentException("Day of week must be between 0 and 6");
        }

        var route = await _context.Routes.FindAsync(dto.RouteId);
        if (route == null)
        {
            throw new InvalidOperationException("Route not found");
        }

        var vehicle = await _context.Vehicles.FindAsync(dto.VehicleId);
        if (vehicle == null)
        {
            throw new InvalidOperationException("Vehicle not found");
        }

        var schedule = new Schedule
        {
            RouteId = dto.RouteId,
            VehicleId = dto.VehicleId,
            DepartureTime = departureTime,
            ArrivalTime = arrivalTime,
            DayOfWeek = (DayOfWeek)dto.DayOfWeek,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Schedules.Add(schedule);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(schedule.Id) ?? throw new Exception("Failed to retrieve created schedule");
    }

    public async Task<ScheduleDto?> UpdateAsync(int id, UpdateScheduleDto dto)
    {
        var schedule = await _context.Schedules.FindAsync(id);
        if (schedule == null)
            return null;

        if (!TimeOnly.TryParse(dto.DepartureTime, out var departureTime))
        {
            throw new ArgumentException("Invalid departure time format");
        }

        if (!TimeOnly.TryParse(dto.ArrivalTime, out var arrivalTime))
        {
            throw new ArgumentException("Invalid arrival time format");
        }

        if (dto.DayOfWeek < 0 || dto.DayOfWeek > 6)
        {
            throw new ArgumentException("Day of week must be between 0 and 6");
        }

        var route = await _context.Routes.FindAsync(dto.RouteId);
        if (route == null)
        {
            throw new InvalidOperationException("Route not found");
        }

        var vehicle = await _context.Vehicles.FindAsync(dto.VehicleId);
        if (vehicle == null)
        {
            throw new InvalidOperationException("Vehicle not found");
        }

        schedule.RouteId = dto.RouteId;
        schedule.VehicleId = dto.VehicleId;
        schedule.DepartureTime = departureTime;
        schedule.ArrivalTime = arrivalTime;
        schedule.DayOfWeek = (DayOfWeek)dto.DayOfWeek;
        schedule.IsActive = dto.IsActive;
        schedule.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(schedule.Id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var schedule = await _context.Schedules.FindAsync(id);
        if (schedule == null)
            return false;

        _context.Schedules.Remove(schedule);
        await _context.SaveChangesAsync();

        return true;
    }

    private static string GetDayOfWeekName(DayOfWeek dayOfWeek)
    {
        return dayOfWeek switch
        {
            DayOfWeek.Monday => "Ponedjeljak",
            DayOfWeek.Tuesday => "Utorak",
            DayOfWeek.Wednesday => "Srijeda",
            DayOfWeek.Thursday => "Četvrtak",
            DayOfWeek.Friday => "Petak",
            DayOfWeek.Saturday => "Subota",
            DayOfWeek.Sunday => "Nedjelja",
            _ => dayOfWeek.ToString()
        };
    }
}
