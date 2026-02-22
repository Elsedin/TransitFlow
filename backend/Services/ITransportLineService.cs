using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ITransportLineService
{
    Task<List<TransportLineDto>> GetAllAsync(string? search = null, bool? isActive = null);
    Task<TransportLineDto?> GetByIdAsync(int id);
    Task<TransportLineDto> CreateAsync(CreateTransportLineDto dto);
    Task<TransportLineDto?> UpdateAsync(int id, UpdateTransportLineDto dto);
    Task<bool> DeleteAsync(int id);
}
