using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IVehicleService
{
    Task<List<VehicleDto>> GetAllAsync(string? search = null, bool? isActive = null);
    Task<VehicleDto?> GetByIdAsync(int id);
    Task<VehicleDto> CreateAsync(CreateVehicleDto dto);
    Task<VehicleDto?> UpdateAsync(int id, UpdateVehicleDto dto);
    Task<bool> DeleteAsync(int id);
}
