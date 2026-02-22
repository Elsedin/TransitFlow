using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ISubscriptionService
{
    Task<SubscriptionMetricsDto> GetMetricsAsync();
    Task<List<SubscriptionDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? userId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? sortBy = null);
    Task<SubscriptionDto?> GetByIdAsync(int id);
    Task<SubscriptionDto> CreateAsync(CreateSubscriptionDto dto);
    Task<SubscriptionDto?> UpdateAsync(int id, UpdateSubscriptionDto dto);
    Task<bool> DeleteAsync(int id);
}
