using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IScheduleService
{
    Task<List<ScheduleDto>> GetAllAsync(int? routeId = null, int? vehicleId = null, int? dayOfWeek = null, bool? isActive = null);
    Task<ScheduleDto?> GetByIdAsync(int id);
    Task<ScheduleDto> CreateAsync(CreateScheduleDto dto);
    Task<ScheduleDto?> UpdateAsync(int id, UpdateScheduleDto dto);
    Task<bool> DeleteAsync(int id);
}
