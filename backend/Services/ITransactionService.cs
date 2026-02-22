using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface ITransactionService
{
    Task<List<TransactionDto>> GetAllAsync(
        string? search = null,
        string? status = null,
        int? userId = null,
        DateTime? dateFrom = null,
        DateTime? dateTo = null,
        string? sortBy = null);
    Task<TransactionDto?> GetByIdAsync(int id);
    Task<TransactionMetricsDto> GetMetricsAsync();
}
