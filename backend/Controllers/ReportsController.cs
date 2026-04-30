using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Administrator")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(IReportService reportService, ILogger<ReportsController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    [HttpPost("generate")]
    public async Task<ActionResult<ReportDto>> GenerateReport([FromBody] ReportRequestDto request)
    {
        try
        {
            ReportDto report;

            var reportType = (request.ReportType ?? string.Empty).Trim().ToLowerInvariant().Replace("-", "_");
            if (string.IsNullOrWhiteSpace(reportType))
            {
                return BadRequest(new { message = "Invalid report type" });
            }

            switch (reportType)
            {
                case "ticket_sales":
                    report = await _reportService.GenerateTicketSalesReportAsync(request);
                    break;
                case "revenue":
                    report = await _reportService.GenerateRevenueReportAsync(request);
                    break;
                case "popular_lines":
                    report = await _reportService.GeneratePopularLinesReportAsync(request);
                    break;
                case "user_activity":
                    report = await _reportService.GenerateUserActivityReportAsync(request);
                    break;
                case "subscriptions":
                    report = await _reportService.GenerateSubscriptionsReportAsync(request);
                    break;
                case "refund_requests":
                    report = await _reportService.GenerateRefundRequestsReportAsync(request);
                    break;
                default:
                    return BadRequest(new { message = "Invalid report type" });
            }

            return Ok(report);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Report generation failed ({ReportType})", request.ReportType);
            return StatusCode(500, new { message = "An error occurred while generating the report", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("ticket-sales/pdf")]
    public async Task<IActionResult> TicketSalesPdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GenerateTicketSalesPdfAsync(request);
            var fileName = $"izvjestaj_prodaja_karata_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Ticket sales PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("refund-requests/pdf")]
    public async Task<IActionResult> RefundRequestsPdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GenerateRefundRequestsPdfAsync(request);
            var fileName = $"izvjestaj_refund_zahtjevi_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund requests PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("revenue/pdf")]
    public async Task<IActionResult> RevenuePdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GenerateRevenuePdfAsync(request);
            var fileName = $"izvjestaj_prihodi_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Revenue PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("popular-lines/pdf")]
    public async Task<IActionResult> PopularLinesPdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GeneratePopularLinesPdfAsync(request);
            var fileName = $"izvjestaj_popularne_linije_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Popular lines PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("user-activity/pdf")]
    public async Task<IActionResult> UserActivityPdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GenerateUserActivityPdfAsync(request);
            var fileName = $"izvjestaj_aktivnost_korisnika_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "User activity PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }

    [HttpPost("subscriptions/pdf")]
    public async Task<IActionResult> SubscriptionsPdf([FromBody] ReportRequestDto request)
    {
        try
        {
            var bytes = await _reportService.GenerateSubscriptionsPdfAsync(request);
            var fileName = $"izvjestaj_pretplate_{DateTime.UtcNow:yyyyMMdd_HHmmss}.pdf";
            return File(bytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Subscriptions PDF generation failed");
            return StatusCode(500, new { message = "An error occurred while generating the PDF", traceId = HttpContext.TraceIdentifier });
        }
    }
}
