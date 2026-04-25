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
    public async Task<ActionResult<List<SubscriptionPackageDto>>> GetAll([FromQuery] bool? isActive = true)
    {
        var query = _context.SubscriptionPackages.AsQueryable();
        if (isActive.HasValue)
        {
            query = query.Where(p => p.IsActive == isActive.Value);
        }

        var packages = await query
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
            .ToListAsync();

        return Ok(packages);
    }
}

