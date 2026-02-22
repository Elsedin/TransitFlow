using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("metrics")]
    public async Task<ActionResult<DashboardMetricsDto>> GetMetrics()
    {
        var metrics = await _dashboardService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet("ticket-sales")]
    public async Task<ActionResult<List<TicketSalesDto>>> GetTicketSales([FromQuery] int days = 30)
    {
        var sales = await _dashboardService.GetTicketSalesAsync(days);
        return Ok(sales);
    }

    [HttpGet("ticket-type-distribution")]
    public async Task<ActionResult<List<TicketTypeDistributionDto>>> GetTicketTypeDistribution()
    {
        var distribution = await _dashboardService.GetTicketTypeDistributionAsync();
        return Ok(distribution);
    }

    [HttpGet("popular-lines")]
    public async Task<ActionResult<List<PopularLineDto>>> GetPopularLines([FromQuery] int top = 5)
    {
        var lines = await _dashboardService.GetPopularLinesAsync(top);
        return Ok(lines);
    }
}
