using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TicketPrice = TransitFlow.API.Models.TicketPrice;

namespace TransitFlow.API.Services;

public class TicketPriceService : ITicketPriceService
{
    private readonly ApplicationDbContext _context;

    public TicketPriceService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TicketPriceDto>> GetAllAsync(int? ticketTypeId = null, int? zoneId = null, bool? isActive = null)
    {
        var query = _context.TicketPrices
            .Include(tp => tp.TicketType)
            .Include(tp => tp.Zone)
            .AsQueryable();

        if (ticketTypeId.HasValue)
        {
            query = query.Where(tp => tp.TicketTypeId == ticketTypeId.Value);
        }

        if (zoneId.HasValue)
        {
            query = query.Where(tp => tp.ZoneId == zoneId.Value);
        }

        if (isActive.HasValue)
        {
            query = query.Where(tp => tp.IsActive == isActive.Value);
        }

        var ticketPrices = await query
            .OrderBy(tp => tp.TicketType!.Name)
            .ThenBy(tp => tp.Zone!.Name)
            .ToListAsync();

        return ticketPrices.Select(tp => new TicketPriceDto
        {
            Id = tp.Id,
            TicketTypeId = tp.TicketTypeId,
            TicketTypeName = tp.TicketType?.Name ?? string.Empty,
            ZoneId = tp.ZoneId,
            ZoneName = tp.Zone?.Name ?? string.Empty,
            Price = tp.Price,
            ValidityDays = tp.TicketType?.ValidityDays ?? 0,
            ValidityDescription = GetValidityDescription(tp.TicketType?.ValidityDays ?? 0),
            ValidFrom = tp.ValidFrom,
            ValidTo = tp.ValidTo,
            CreatedAt = tp.CreatedAt,
            IsActive = tp.IsActive
        }).ToList();
    }

    public async Task<TicketPriceDto?> GetByIdAsync(int id)
    {
        var ticketPrice = await _context.TicketPrices
            .Include(tp => tp.TicketType)
            .Include(tp => tp.Zone)
            .FirstOrDefaultAsync(tp => tp.Id == id);

        if (ticketPrice == null)
            return null;

        return new TicketPriceDto
        {
            Id = ticketPrice.Id,
            TicketTypeId = ticketPrice.TicketTypeId,
            TicketTypeName = ticketPrice.TicketType?.Name ?? string.Empty,
            ZoneId = ticketPrice.ZoneId,
            ZoneName = ticketPrice.Zone?.Name ?? string.Empty,
            Price = ticketPrice.Price,
            ValidityDays = ticketPrice.TicketType?.ValidityDays ?? 0,
            ValidityDescription = GetValidityDescription(ticketPrice.TicketType?.ValidityDays ?? 0),
            ValidFrom = ticketPrice.ValidFrom,
            ValidTo = ticketPrice.ValidTo,
            CreatedAt = ticketPrice.CreatedAt,
            IsActive = ticketPrice.IsActive
        };
    }

    public async Task<TicketPriceDto> CreateAsync(CreateTicketPriceDto dto)
    {
        var ticketType = await _context.TicketTypes.FindAsync(dto.TicketTypeId);
        if (ticketType == null)
        {
            throw new InvalidOperationException("Ticket type not found");
        }

        var zone = await _context.Zones.FindAsync(dto.ZoneId);
        if (zone == null)
        {
            throw new InvalidOperationException("Zone not found");
        }

        var ticketPrice = new TicketPrice
        {
            TicketTypeId = dto.TicketTypeId,
            ZoneId = dto.ZoneId,
            Price = dto.Price,
            ValidFrom = dto.ValidFrom,
            ValidTo = dto.ValidTo,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.TicketPrices.Add(ticketPrice);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(ticketPrice.Id) ?? throw new Exception("Failed to retrieve created ticket price");
    }

    public async Task<TicketPriceDto?> UpdateAsync(int id, UpdateTicketPriceDto dto)
    {
        var ticketPrice = await _context.TicketPrices.FindAsync(id);
        if (ticketPrice == null)
            return null;

        var ticketType = await _context.TicketTypes.FindAsync(dto.TicketTypeId);
        if (ticketType == null)
        {
            throw new InvalidOperationException("Ticket type not found");
        }

        var zone = await _context.Zones.FindAsync(dto.ZoneId);
        if (zone == null)
        {
            throw new InvalidOperationException("Zone not found");
        }

        ticketPrice.TicketTypeId = dto.TicketTypeId;
        ticketPrice.ZoneId = dto.ZoneId;
        ticketPrice.Price = dto.Price;
        ticketPrice.ValidFrom = dto.ValidFrom;
        ticketPrice.ValidTo = dto.ValidTo;
        ticketPrice.IsActive = dto.IsActive;
        ticketPrice.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return await GetByIdAsync(ticketPrice.Id);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var ticketPrice = await _context.TicketPrices.FindAsync(id);
        if (ticketPrice == null)
            return false;

        _context.TicketPrices.Remove(ticketPrice);
        await _context.SaveChangesAsync();

        return true;
    }

    private static string GetValidityDescription(int validityDays)
    {
        return validityDays switch
        {
            0 => "Jedan put",
            1 => "24 sata",
            30 => "30 dana",
            365 => "365 dana",
            _ => $"{validityDays} dana"
        };
    }
}
