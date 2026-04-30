using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public interface IReportService
{
    Task<ReportDto> GenerateTicketSalesReportAsync(ReportRequestDto request);
    Task<ReportDto> GenerateRevenueReportAsync(ReportRequestDto request);
    Task<ReportDto> GeneratePopularLinesReportAsync(ReportRequestDto request);
    Task<ReportDto> GenerateUserActivityReportAsync(ReportRequestDto request);
    Task<ReportDto> GenerateSubscriptionsReportAsync(ReportRequestDto request);
    Task<ReportDto> GenerateRefundRequestsReportAsync(ReportRequestDto request);
    Task<byte[]> GenerateTicketSalesPdfAsync(ReportRequestDto request);
    Task<byte[]> GenerateRefundRequestsPdfAsync(ReportRequestDto request);
    Task<byte[]> GenerateRevenuePdfAsync(ReportRequestDto request);
    Task<byte[]> GeneratePopularLinesPdfAsync(ReportRequestDto request);
    Task<byte[]> GenerateUserActivityPdfAsync(ReportRequestDto request);
    Task<byte[]> GenerateSubscriptionsPdfAsync(ReportRequestDto request);
}
