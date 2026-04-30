using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IReportService
{
    Task<ReportDto> GenerateTicketSalesReportAsync(ReportRequestDto request);
    Task<byte[]> GenerateTicketSalesPdfAsync(ReportRequestDto request);
    Task<byte[]> GenerateRefundRequestsPdfAsync(ReportRequestDto request);
}
