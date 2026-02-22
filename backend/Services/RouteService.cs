using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Route = TransitFlow.API.Models.Route;
using RouteStation = TransitFlow.API.Models.RouteStation;

namespace TransitFlow.API.Services;

public class RouteService : IRouteService
{
    private readonly ApplicationDbContext _context;

    public RouteService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<RouteDto>> GetAllAsync(string? search = null, bool? isActive = null)
    {
        var query = _context.Routes
            .Include(r => r.TransportLine)
            .Include(r => r.RouteStations)
                .ThenInclude(rs => rs.Station)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(r => 
                r.Origin.Contains(search) || 
                r.Destination.Contains(search) ||
                r.TransportLine!.Name.Contains(search) ||
                r.TransportLine.LineNumber.Contains(search));
        }

        if (isActive.HasValue)
        {
            query = query.Where(r => r.IsActive == isActive.Value);
        }

        var routes = await query
            .OrderBy(r => r.TransportLine!.LineNumber)
            .ThenBy(r => r.Origin)
            .ToListAsync();

        return routes.Select(r => new RouteDto
        {
            Id = r.Id,
            Name = $"{r.TransportLine!.LineNumber} - {r.Origin} - {r.Destination}",
            Origin = r.Origin,
            Destination = r.Destination,
            TransportLineId = r.TransportLineId,
            TransportLineName = r.TransportLine.Name,
            TransportLineNumber = r.TransportLine.LineNumber,
            Distance = r.Distance,
            EstimatedDurationMinutes = r.EstimatedDurationMinutes,
            IsActive = r.IsActive,
            Stations = r.RouteStations
                .OrderBy(rs => rs.Order)
                .Select(rs => new RouteStationDto
                {
                    Id = rs.Id,
                    StationId = rs.StationId,
                    StationName = rs.Station!.Name,
                    StationAddress = rs.Station.Address,
                    Order = rs.Order
                })
                .ToList()
        }).ToList();
    }

    public async Task<RouteDto?> GetByIdAsync(int id)
    {
        var route = await _context.Routes
            .Include(r => r.TransportLine)
            .Include(r => r.RouteStations)
                .ThenInclude(rs => rs.Station)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (route == null)
            return null;

        return new RouteDto
        {
            Id = route.Id,
            Name = $"{route.TransportLine!.LineNumber} - {route.Origin} - {route.Destination}",
            Origin = route.Origin,
            Destination = route.Destination,
            TransportLineId = route.TransportLineId,
            TransportLineName = route.TransportLine.Name,
            TransportLineNumber = route.TransportLine.LineNumber,
            Distance = route.Distance,
            EstimatedDurationMinutes = route.EstimatedDurationMinutes,
            IsActive = route.IsActive,
            Stations = route.RouteStations
                .OrderBy(rs => rs.Order)
                .Select(rs => new RouteStationDto
                {
                    Id = rs.Id,
                    StationId = rs.StationId,
                    StationName = rs.Station!.Name,
                    StationAddress = rs.Station.Address,
                    Order = rs.Order
                })
                .ToList()
        };
    }

    public async Task<RouteDto> CreateAsync(CreateRouteDto dto)
    {
        var route = new Route
        {
            TransportLineId = dto.TransportLineId,
            Origin = dto.Origin,
            Destination = dto.Destination,
            Distance = dto.Distance,
            EstimatedDurationMinutes = dto.EstimatedDurationMinutes,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Routes.Add(route);
        await _context.SaveChangesAsync();

        foreach (var stationDto in dto.Stations.OrderBy(s => s.Order))
        {
            var routeStation = new RouteStation
            {
                RouteId = route.Id,
                StationId = stationDto.StationId,
                Order = stationDto.Order,
                CreatedAt = DateTime.UtcNow
            };
            _context.RouteStations.Add(routeStation);
        }

        await _context.SaveChangesAsync();

        return await GetByIdAsync(route.Id) ?? throw new InvalidOperationException("Failed to create route");
    }

    public async Task<RouteDto?> UpdateAsync(int id, UpdateRouteDto dto)
    {
        var route = await _context.Routes
            .Include(r => r.RouteStations)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (route == null)
            return null;

        route.TransportLineId = dto.TransportLineId;
        route.Origin = dto.Origin;
        route.Destination = dto.Destination;
        route.Distance = dto.Distance;
        route.EstimatedDurationMinutes = dto.EstimatedDurationMinutes;
        route.IsActive = dto.IsActive;
        route.UpdatedAt = DateTime.UtcNow;

        var existingStationIds = dto.Stations
            .Where(s => s.Id.HasValue)
            .Select(s => s.Id!.Value)
            .ToList();

        var stationsToRemove = route.RouteStations
            .Where(rs => !existingStationIds.Contains(rs.Id))
            .ToList();

        foreach (var stationToRemove in stationsToRemove)
        {
            _context.RouteStations.Remove(stationToRemove);
        }

        foreach (var stationDto in dto.Stations)
        {
            if (stationDto.Id.HasValue)
            {
                var existingStation = route.RouteStations
                    .FirstOrDefault(rs => rs.Id == stationDto.Id.Value);
                
                if (existingStation != null)
                {
                    existingStation.StationId = stationDto.StationId;
                    existingStation.Order = stationDto.Order;
                }
            }
            else
            {
                var newRouteStation = new RouteStation
                {
                    RouteId = route.Id,
                    StationId = stationDto.StationId,
                    Order = stationDto.Order,
                    CreatedAt = DateTime.UtcNow
                };
                _context.RouteStations.Add(newRouteStation);
            }
        }

        await _context.SaveChangesAsync();

        return await GetByIdAsync(route.Id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var route = await _context.Routes
            .Include(r => r.RouteStations)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (route == null)
            return false;

        _context.RouteStations.RemoveRange(route.RouteStations);
        _context.Routes.Remove(route);
        await _context.SaveChangesAsync();

        return true;
    }
}
