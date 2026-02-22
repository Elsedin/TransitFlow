using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IDashboardService
{
    Task<DashboardMetricsDto> GetMetricsAsync();
    Task<List<TicketSalesDto>> GetTicketSalesAsync(int days = 30);
    Task<List<TicketTypeDistributionDto>> GetTicketTypeDistributionAsync();
    Task<List<PopularLineDto>> GetPopularLinesAsync(int top = 5);
}
