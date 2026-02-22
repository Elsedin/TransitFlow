using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface INotificationService
{
    Task<List<NotificationDto>> GetAllAsync(
        int? userId = null,
        string? type = null,
        bool? isRead = null,
        bool? isActive = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? search = null);
    Task<NotificationDto?> GetByIdAsync(int id);
    Task<NotificationMetricsDto> GetMetricsAsync();
    Task<NotificationDto> CreateAsync(CreateNotificationDto dto);
    Task<NotificationDto?> UpdateAsync(int id, UpdateNotificationDto dto);
    Task<bool> DeleteAsync(int id);
    Task<bool> MarkAsReadAsync(int id);
}
