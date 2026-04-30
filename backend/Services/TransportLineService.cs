using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class TransportLineService : ITransportLineService
{
    private readonly ApplicationDbContext _context;

    public TransportLineService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TransportLineDto>> GetAllAsync(string? search = null, bool? isActive = null)
    {
        var query = BuildFilteredQuery(search, isActive);
        var lines = await query.ToListAsync();
        return lines.Select(MapToDto).ToList();
    }

    public async Task<PagedResultDto<TransportLineDto>> GetPagedAsync(int page, int pageSize, string? search = null, bool? isActive = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = BuildFilteredQuery(search, isActive);
        var total = await query.CountAsync();
        var lines = await query
            .OrderBy(tl => tl.LineNumber)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<TransportLineDto>
        {
            Items = lines.Select(MapToDto).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<TransportLineDto?> GetByIdAsync(int id)
    {
        var line = await _context.TransportLines
            .Include(tl => tl.TransportType)
            .Include(tl => tl.Routes)
            .FirstOrDefaultAsync(tl => tl.Id == id);

        if (line == null)
        {
            return null;
        }

        var firstRoute = line.Routes.FirstOrDefault();
        return new TransportLineDto
        {
            Id = line.Id,
            LineNumber = line.LineNumber,
            Name = line.Name,
            Origin = firstRoute?.Origin ?? string.Empty,
            Destination = firstRoute?.Destination ?? string.Empty,
            TransportTypeName = line.TransportType?.Name ?? string.Empty,
            IsActive = line.IsActive
        };
    }

    public async Task<TransportLineDto> CreateAsync(CreateTransportLineDto dto)
    {
        var transportLine = new Models.TransportLine
        {
            LineNumber = dto.LineNumber,
            Name = dto.Name,
            TransportTypeId = dto.TransportTypeId,
            IsActive = dto.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        _context.TransportLines.Add(transportLine);
        await _context.SaveChangesAsync();

        var route = new Models.Route
        {
            TransportLineId = transportLine.Id,
            Origin = dto.Origin,
            Destination = dto.Destination,
            Distance = dto.Distance,
            EstimatedDurationMinutes = dto.EstimatedDurationMinutes,
            IsActive = dto.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        _context.Routes.Add(route);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(transportLine.Id) ?? throw new InvalidOperationException("Failed to create transport line");
    }

    public async Task<TransportLineDto?> UpdateAsync(int id, UpdateTransportLineDto dto)
    {
        var transportLine = await _context.TransportLines
            .Include(tl => tl.Routes)
            .FirstOrDefaultAsync(tl => tl.Id == id);

        if (transportLine == null)
        {
            return null;
        }

        transportLine.LineNumber = dto.LineNumber;
        transportLine.Name = dto.Name;
        transportLine.TransportTypeId = dto.TransportTypeId;
        transportLine.IsActive = dto.IsActive;
        transportLine.UpdatedAt = DateTime.UtcNow;

        var route = transportLine.Routes.FirstOrDefault();
        if (route != null)
        {
            route.Origin = dto.Origin;
            route.Destination = dto.Destination;
            route.Distance = dto.Distance;
            route.EstimatedDurationMinutes = dto.EstimatedDurationMinutes;
            route.IsActive = dto.IsActive;
            route.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            route = new Models.Route
            {
                TransportLineId = transportLine.Id,
                Origin = dto.Origin,
                Destination = dto.Destination,
                Distance = dto.Distance,
                EstimatedDurationMinutes = dto.EstimatedDurationMinutes,
                IsActive = dto.IsActive,
                CreatedAt = DateTime.UtcNow
            };
            _context.Routes.Add(route);
        }

        await _context.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var transportLine = await _context.TransportLines
            .Include(tl => tl.Routes)
            .FirstOrDefaultAsync(tl => tl.Id == id);

        if (transportLine == null)
        {
            return false;
        }

        _context.Routes.RemoveRange(transportLine.Routes);
        _context.TransportLines.Remove(transportLine);
        await _context.SaveChangesAsync();

        return true;
    }

    private IQueryable<Models.TransportLine> BuildFilteredQuery(string? search, bool? isActive)
    {
        var query = _context.TransportLines
            .Include(tl => tl.TransportType)
            .Include(tl => tl.Routes)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(tl =>
                tl.LineNumber.ToLower().Contains(searchLower) ||
                tl.Name.ToLower().Contains(searchLower) ||
                tl.Routes.Any(r => r.Origin.ToLower().Contains(searchLower) ||
                                   r.Destination.ToLower().Contains(searchLower)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(tl => tl.IsActive == isActive.Value);
        }

        return query;
    }

    private static TransportLineDto MapToDto(Models.TransportLine tl)
    {
        var firstRoute = tl.Routes.FirstOrDefault();
        return new TransportLineDto
        {
            Id = tl.Id,
            LineNumber = tl.LineNumber,
            Name = tl.Name,
            Origin = firstRoute?.Origin ?? string.Empty,
            Destination = firstRoute?.Destination ?? string.Empty,
            TransportTypeName = tl.TransportType?.Name ?? string.Empty,
            IsActive = tl.IsActive
        };
    }
}
