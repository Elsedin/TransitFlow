using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransitFlow.API.Models;

namespace TransitFlow.API.Services;

public class CountryService : ICountryService
{
    private readonly ApplicationDbContext _context;

    public CountryService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<CountryDto>> GetAllAsync(string? search = null, bool? isActive = null)
    {
        var query = BuildFilteredQuery(search, isActive);
        var items = await query
            .OrderBy(c => c.Name)
            .ToListAsync();

        return items.Select(Map).ToList();
    }

    public async Task<PagedResultDto<CountryDto>> GetPagedAsync(int page, int pageSize, string? search = null, bool? isActive = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = BuildFilteredQuery(search, isActive);
        var total = await query.CountAsync();
        var items = await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<CountryDto>
        {
            Items = items.Select(Map).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<CountryDto?> GetByIdAsync(int id)
    {
        var item = await _context.Countries
            .Include(c => c.Cities)
            .FirstOrDefaultAsync(c => c.Id == id);

        return item == null ? null : Map(item);
    }

    public async Task<CountryDto> CreateAsync(CreateCountryDto dto)
    {
        var name = dto.Name.Trim();
        var code = string.IsNullOrWhiteSpace(dto.Code) ? null : dto.Code.Trim().ToUpperInvariant();

        if (await _context.Countries.AnyAsync(c => c.Name.ToLower() == name.ToLower()))
            throw new InvalidOperationException("Država sa istim nazivom već postoji.");

        if (!string.IsNullOrWhiteSpace(code) &&
            await _context.Countries.AnyAsync(c => c.Code != null && c.Code.ToLower() == code.ToLower()))
            throw new InvalidOperationException("Država sa istim kodom već postoji.");

        var entity = new Country
        {
            Name = name,
            Code = code,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Countries.Add(entity);
        await _context.SaveChangesAsync();

        await _context.Entry(entity).Collection(e => e.Cities).LoadAsync();
        return Map(entity);
    }

    public async Task<CountryDto?> UpdateAsync(int id, UpdateCountryDto dto)
    {
        var entity = await _context.Countries
            .Include(c => c.Cities)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (entity == null) return null;

        var name = dto.Name.Trim();
        var code = string.IsNullOrWhiteSpace(dto.Code) ? null : dto.Code.Trim().ToUpperInvariant();

        if (await _context.Countries.AnyAsync(c => c.Id != id && c.Name.ToLower() == name.ToLower()))
            throw new InvalidOperationException("Država sa istim nazivom već postoji.");

        if (!string.IsNullOrWhiteSpace(code) &&
            await _context.Countries.AnyAsync(c => c.Id != id && c.Code != null && c.Code.ToLower() == code.ToLower()))
            throw new InvalidOperationException("Država sa istim kodom već postoji.");

        entity.Name = name;
        entity.Code = code;
        entity.IsActive = dto.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return Map(entity);
    }

    public async Task DeleteAsync(int id)
    {
        var entity = await _context.Countries.FirstOrDefaultAsync(c => c.Id == id);
        if (entity == null) return;

        var hasCities = await _context.Cities.AnyAsync(c => c.CountryId == id);
        if (hasCities)
            throw new InvalidOperationException("Brisanje nije moguće jer postoje gradovi povezani sa ovom državom.");

        _context.Countries.Remove(entity);
        await _context.SaveChangesAsync();
    }

    private static CountryDto Map(Country c)
    {
        return new CountryDto
        {
            Id = c.Id,
            Name = c.Name,
            Code = c.Code,
            IsActive = c.IsActive,
            CityCount = c.Cities.Count
        };
    }

    private IQueryable<Country> BuildFilteredQuery(string? search, bool? isActive)
    {
        var query = _context.Countries
            .Include(c => c.Cities)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(c =>
                c.Name.ToLower().Contains(s) ||
                (c.Code != null && c.Code.ToLower().Contains(s)));
        }

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        return query;
    }
}

