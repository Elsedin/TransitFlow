using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ITicketService
{
    Task<List<TicketDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? ticketTypeId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null);
    Task<TicketDto?> GetByIdAsync(int id);
    Task<TicketMetricsDto> GetMetricsAsync();
}
