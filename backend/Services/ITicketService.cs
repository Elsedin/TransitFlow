using System.Security.Claims;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ITicketService
{
    Task<List<TicketDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? ticketTypeId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        int? userId = null);
    
    Task<PagedResultDto<TicketDto>> GetPagedAsync(
        int page,
        int pageSize,
        string? search = null,
        string? status = null,
        int? ticketTypeId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        int? userId = null);
    Task<TicketDto?> GetByIdAsync(int id);
    Task<TicketMetricsDto> GetMetricsAsync();
    Task<TicketDto> PurchaseAsync(PurchaseTicketDto dto, int userId);
    Task<TicketValidationResultDto> ValidateAsync(Guid publicId);
}
