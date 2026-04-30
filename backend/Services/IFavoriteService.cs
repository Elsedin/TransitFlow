using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IFavoriteService
{
    Task<List<FavoriteLineDto>> GetAllAsync(int userId);
    Task<PagedResultDto<FavoriteLineDto>> GetPagedAsync(int userId, int page, int pageSize, string? search = null);
    Task<FavoriteLineDto?> GetByIdAsync(int id);
    Task<bool> IsFavoriteAsync(int userId, int transportLineId);
    Task<FavoriteLineDto> CreateAsync(int userId, CreateFavoriteLineDto dto);
    Task<bool> DeleteAsync(int userId, int transportLineId);
    Task<bool> DeleteByIdAsync(int id);
}
