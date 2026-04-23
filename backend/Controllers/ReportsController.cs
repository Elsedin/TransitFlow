using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
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
            
            switch (request.ReportType.ToLower())
            {
                case "ticket_sales":
                    report = await _reportService.GenerateTicketSalesReportAsync(request);
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
}
