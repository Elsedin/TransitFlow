using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
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
            return StatusCode(500, new { message = "An error occurred while generating the report", error = ex.Message });
        }
    }
}
