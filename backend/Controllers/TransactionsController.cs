using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TransitFlow.API.DTOs;
using TransitFlow.API.Services;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TransactionsController : ControllerBase
{
    private readonly ITransactionService _transactionService;

    public TransactionsController(ITransactionService transactionService)
    {
        _transactionService = transactionService;
    }

    [HttpGet("metrics")]
    public async Task<ActionResult<TransactionMetricsDto>> GetMetrics()
    {
        var metrics = await _transactionService.GetMetricsAsync();
        return Ok(metrics);
    }

    [HttpGet]
    public async Task<ActionResult<List<TransactionDto>>> GetAll(
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] int? userId = null,
        [FromQuery] DateTime? dateFrom = null,
        [FromQuery] DateTime? dateTo = null,
        [FromQuery] string? sortBy = null)
    {
        var transactions = await _transactionService.GetAllAsync(search, status, userId, dateFrom, dateTo, sortBy);
        return Ok(transactions);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TransactionDto>> GetById(int id)
    {
        var transaction = await _transactionService.GetByIdAsync(id);
        
        if (transaction == null)
        {
            return NotFound();
        }

        return Ok(transaction);
    }
}
