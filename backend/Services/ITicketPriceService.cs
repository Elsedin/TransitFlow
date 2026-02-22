using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ITicketPriceService
{
    Task<List<TicketPriceDto>> GetAllAsync(int? ticketTypeId = null, int? zoneId = null, bool? isActive = null);
    Task<TicketPriceDto?> GetByIdAsync(int id);
    Task<TicketPriceDto> CreateAsync(CreateTicketPriceDto dto);
    Task<TicketPriceDto?> UpdateAsync(int id, UpdateTicketPriceDto dto);
    Task<bool> DeleteAsync(int id);
}
