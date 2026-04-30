using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Vehicle = TransitFlow.API.Models.Vehicle;

namespace TransitFlow.API.Services;

public class VehicleService : IVehicleService
{
    private readonly ApplicationDbContext _context;

    public VehicleService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<VehicleDto>> GetAllAsync(string? search = null, bool? isActive = null)
    {
        var query = BuildFilteredQuery(search, isActive);
        var vehicles = await query.OrderBy(v => v.LicensePlate).ToListAsync();
        return vehicles.Select(MapToDto).ToList();
    }

    public async Task<PagedResultDto<VehicleDto>> GetPagedAsync(int page, int pageSize, string? search = null, bool? isActive = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = BuildFilteredQuery(search, isActive);
        var total = await query.CountAsync();
        var vehicles = await query
            .OrderBy(v => v.LicensePlate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<VehicleDto>
        {
            Items = vehicles.Select(MapToDto).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<VehicleDto?> GetByIdAsync(int id)
    {
        var vehicle = await _context.Vehicles
            .Include(v => v.TransportType)
            .FirstOrDefaultAsync(v => v.Id == id);

        if (vehicle == null)
            return null;

        return new VehicleDto
        {
            Id = vehicle.Id,
            LicensePlate = vehicle.LicensePlate,
            Make = vehicle.Make,
            Model = vehicle.Model,
            Year = vehicle.Year,
            Capacity = vehicle.Capacity,
            TransportTypeId = vehicle.TransportTypeId,
            TransportTypeName = vehicle.TransportType?.Name ?? string.Empty,
            IsActive = vehicle.IsActive
        };
    }

    private IQueryable<Vehicle> BuildFilteredQuery(string? search, bool? isActive)
    {
        var query = _context.Vehicles
            .Include(v => v.TransportType)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(v =>
                v.LicensePlate.ToLower().Contains(searchLower) ||
                (v.Make != null && v.Make.ToLower().Contains(searchLower)) ||
                (v.Model != null && v.Model.ToLower().Contains(searchLower)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(v => v.IsActive == isActive.Value);
        }

        return query;
    }

    private static VehicleDto MapToDto(Vehicle v)
    {
        return new VehicleDto
        {
            Id = v.Id,
            LicensePlate = v.LicensePlate,
            Make = v.Make,
            Model = v.Model,
            Year = v.Year,
            Capacity = v.Capacity,
            TransportTypeId = v.TransportTypeId,
            TransportTypeName = v.TransportType?.Name ?? string.Empty,
            IsActive = v.IsActive
        };
    }

    public async Task<VehicleDto> CreateAsync(CreateVehicleDto dto)
    {
        var vehicle = new Vehicle
        {
            LicensePlate = dto.LicensePlate.Trim(),
            Make = string.IsNullOrWhiteSpace(dto.Make) ? null : dto.Make.Trim(),
            Model = string.IsNullOrWhiteSpace(dto.Model) ? null : dto.Model.Trim(),
            Year = dto.Year,
            Capacity = dto.Capacity,
            TransportTypeId = dto.TransportTypeId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Vehicles.Add(vehicle);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(vehicle.Id) ?? throw new Exception("Failed to retrieve created vehicle");
    }

    public async Task<VehicleDto?> UpdateAsync(int id, UpdateVehicleDto dto)
    {
        var vehicle = await _context.Vehicles.FindAsync(id);
        if (vehicle == null)
            return null;

        vehicle.LicensePlate = dto.LicensePlate.Trim();
        vehicle.Make = string.IsNullOrWhiteSpace(dto.Make) ? null : dto.Make.Trim();
        vehicle.Model = string.IsNullOrWhiteSpace(dto.Model) ? null : dto.Model.Trim();
        vehicle.Year = dto.Year;
        vehicle.Capacity = dto.Capacity;
        vehicle.TransportTypeId = dto.TransportTypeId;
        vehicle.IsActive = dto.IsActive;
        vehicle.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(vehicle.Id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var vehicle = await _context.Vehicles
            .Include(v => v.Schedules)
            .FirstOrDefaultAsync(v => v.Id == id);

        if (vehicle == null)
            return false;

        if (vehicle.Schedules.Any())
        {
            throw new InvalidOperationException("Cannot delete vehicle that is used in schedules");
        }

        _context.Vehicles.Remove(vehicle);
        await _context.SaveChangesAsync();

        return true;
    }
}
