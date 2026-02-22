using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IUserService
{
    Task<List<UserDto>> GetAllAsync(
        string? search = null,
        bool? isActive = null,
        string? sortBy = null);
    Task<UserDto?> GetByIdAsync(int id);
    Task<UserMetricsDto> GetMetricsAsync();
    Task<UserDto> CreateAsync(CreateUserDto dto);
    Task<UserDto?> UpdateAsync(int id, UpdateUserDto dto);
    Task<bool> ToggleActiveAsync(int id);
}
