using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ICountryService
{
    Task<List<CountryDto>> GetAllAsync(string? search = null, bool? isActive = null);
    Task<PagedResultDto<CountryDto>> GetPagedAsync(int page, int pageSize, string? search = null, bool? isActive = null);
    Task<CountryDto?> GetByIdAsync(int id);
    Task<CountryDto> CreateAsync(CreateCountryDto dto);
    Task<CountryDto?> UpdateAsync(int id, UpdateCountryDto dto);
    Task DeleteAsync(int id);
}

