using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IRouteService
{
    Task<List<RouteDto>> GetAllAsync(string? search = null, bool? isActive = null);
    Task<RouteDto?> GetByIdAsync(int id);
    Task<RouteDto> CreateAsync(CreateRouteDto dto);
    Task<RouteDto?> UpdateAsync(int id, UpdateRouteDto dto);
    Task<bool> DeleteAsync(int id);
}
