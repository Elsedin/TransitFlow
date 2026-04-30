using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Controllers;

[ApiController]
[Route("api/subscription-packages")]
[Authorize]
public class SubscriptionPackagesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SubscriptionPackagesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResultDto<SubscriptionPackageDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool? isActive = true)
    {
        return await GetPaged(page, pageSize, isActive);
    }

    [HttpGet("paged")]
    public async Task<ActionResult<PagedResultDto<SubscriptionPackageDto>>> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool? isActive = true)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = _context.SubscriptionPackages.AsQueryable();
        if (isActive.HasValue)
        {
            query = query.Where(p => p.IsActive == isActive.Value);
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(p => p.DisplayName)
            .Select(p => new SubscriptionPackageDto
            {
                Id = p.Id,
                Key = p.Key,
                DisplayName = p.DisplayName,
                DurationDays = p.DurationDays,
                Price = p.Price,
                MaxZoneId = p.MaxZoneId,
                IsActive = p.IsActive
            })
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new PagedResultDto<SubscriptionPackageDto>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        });
    }
}

