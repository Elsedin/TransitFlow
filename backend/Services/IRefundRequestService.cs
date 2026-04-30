using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IRefundRequestService
{
    Task<RefundRequestDto> CreateAsync(int userId, CreateRefundRequestDto dto);
    Task<List<RefundRequestDto>> GetMyAsync(int userId);
    Task<PagedResultDto<RefundRequestDto>> GetMyPagedAsync(int userId, int page, int pageSize);
    Task<List<RefundRequestDto>> GetAllAsync(string? status = null);
    Task<PagedResultDto<RefundRequestDto>> GetPagedAsync(int page, int pageSize, string? status = null);
    Task<RefundRequestDto> ApproveAsync(int adminId, int requestId, ResolveRefundRequestDto dto);
    Task<RefundRequestDto> RejectAsync(int adminId, int requestId, ResolveRefundRequestDto dto);
}

