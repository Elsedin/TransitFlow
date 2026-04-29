using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IRefundRequestService
{
    Task<RefundRequestDto> CreateAsync(int userId, CreateRefundRequestDto dto);
    Task<List<RefundRequestDto>> GetMyAsync(int userId);
    Task<List<RefundRequestDto>> GetAllAsync(string? status = null);
    Task<RefundRequestDto> ApproveAsync(int adminId, int requestId, ResolveRefundRequestDto dto);
    Task<RefundRequestDto> RejectAsync(int adminId, int requestId, ResolveRefundRequestDto dto);
}

