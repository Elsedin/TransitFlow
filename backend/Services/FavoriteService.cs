using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using FavoriteLine = TransitFlow.API.Models.FavoriteLine;

namespace TransitFlow.API.Services;

public class FavoriteService : IFavoriteService
{
    private readonly ApplicationDbContext _context;

    public FavoriteService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<FavoriteLineDto>> GetAllAsync(int userId)
    {
        var favorites = await _context.FavoriteLines
            .Include(f => f.User)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.TransportType)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.Routes)
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();

        return favorites.Select(f => new FavoriteLineDto
        {
            Id = f.Id,
            UserId = f.UserId,
            UserEmail = f.User?.Email ?? string.Empty,
            TransportLineId = f.TransportLineId,
            TransportLineNumber = f.TransportLine?.LineNumber ?? string.Empty,
            TransportLineName = f.TransportLine?.Name ?? string.Empty,
            Origin = f.TransportLine?.Routes.FirstOrDefault()?.Origin ?? string.Empty,
            Destination = f.TransportLine?.Routes.FirstOrDefault()?.Destination ?? string.Empty,
            TransportTypeName = f.TransportLine?.TransportType?.Name ?? string.Empty,
            CreatedAt = f.CreatedAt
        }).ToList();
    }

    public async Task<PagedResultDto<FavoriteLineDto>> GetPagedAsync(int userId, int page, int pageSize, string? search = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = _context.FavoriteLines
            .Include(f => f.User)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.TransportType)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.Routes)
            .Where(f => f.UserId == userId);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(f =>
                (f.TransportLine != null && (
                    f.TransportLine.LineNumber.ToLower().Contains(s) ||
                    f.TransportLine.Name.ToLower().Contains(s)
                )) ||
                (f.TransportLine != null && f.TransportLine.Routes.Any(r =>
                    r.Origin.ToLower().Contains(s) || r.Destination.ToLower().Contains(s)
                )));
        }

        var total = await query.CountAsync();

        var favorites = await query
            .OrderByDescending(f => f.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<FavoriteLineDto>
        {
            Items = favorites.Select(f => new FavoriteLineDto
            {
                Id = f.Id,
                UserId = f.UserId,
                UserEmail = f.User?.Email ?? string.Empty,
                TransportLineId = f.TransportLineId,
                TransportLineNumber = f.TransportLine?.LineNumber ?? string.Empty,
                TransportLineName = f.TransportLine?.Name ?? string.Empty,
                Origin = f.TransportLine?.Routes.FirstOrDefault()?.Origin ?? string.Empty,
                Destination = f.TransportLine?.Routes.FirstOrDefault()?.Destination ?? string.Empty,
                TransportTypeName = f.TransportLine?.TransportType?.Name ?? string.Empty,
                CreatedAt = f.CreatedAt
            }).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<FavoriteLineDto?> GetByIdAsync(int id)
    {
        var favorite = await _context.FavoriteLines
            .Include(f => f.User)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.TransportType)
            .Include(f => f.TransportLine)
                .ThenInclude(tl => tl!.Routes)
            .FirstOrDefaultAsync(f => f.Id == id);

        if (favorite == null)
            return null;

        return new FavoriteLineDto
        {
            Id = favorite.Id,
            UserId = favorite.UserId,
            UserEmail = favorite.User?.Email ?? string.Empty,
            TransportLineId = favorite.TransportLineId,
            TransportLineNumber = favorite.TransportLine?.LineNumber ?? string.Empty,
            TransportLineName = favorite.TransportLine?.Name ?? string.Empty,
            Origin = favorite.TransportLine?.Routes.FirstOrDefault()?.Origin ?? string.Empty,
            Destination = favorite.TransportLine?.Routes.FirstOrDefault()?.Destination ?? string.Empty,
            TransportTypeName = favorite.TransportLine?.TransportType?.Name ?? string.Empty,
            CreatedAt = favorite.CreatedAt
        };
    }

    public async Task<bool> IsFavoriteAsync(int userId, int transportLineId)
    {
        return await _context.FavoriteLines
            .AnyAsync(f => f.UserId == userId && f.TransportLineId == transportLineId);
    }

    public async Task<FavoriteLineDto> CreateAsync(int userId, CreateFavoriteLineDto dto)
    {
        var existingFavorite = await _context.FavoriteLines
            .FirstOrDefaultAsync(f => f.UserId == userId && f.TransportLineId == dto.TransportLineId);

        if (existingFavorite != null)
        {
            throw new InvalidOperationException("Linija je već u omiljenim");
        }

        if (!await _context.TransportLines.AnyAsync(tl => tl.Id == dto.TransportLineId))
        {
            throw new ArgumentException("Transport line not found");
        }

        var favorite = new FavoriteLine
        {
            UserId = userId,
            TransportLineId = dto.TransportLineId,
            CreatedAt = DateTime.UtcNow
        };

        _context.FavoriteLines.Add(favorite);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(favorite.Id) ?? throw new Exception("Failed to retrieve created favorite");
    }

    public async Task<bool> DeleteAsync(int userId, int transportLineId)
    {
        var favorite = await _context.FavoriteLines
            .FirstOrDefaultAsync(f => f.UserId == userId && f.TransportLineId == transportLineId);

        if (favorite == null)
            return false;

        _context.FavoriteLines.Remove(favorite);
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteByIdAsync(int id)
    {
        var favorite = await _context.FavoriteLines.FindAsync(id);
        if (favorite == null)
            return false;

        _context.FavoriteLines.Remove(favorite);
        await _context.SaveChangesAsync();

        return true;
    }
}
