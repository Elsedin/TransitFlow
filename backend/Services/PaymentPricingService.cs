using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Constants;
using TransitFlow.API.Data;

namespace TransitFlow.API.Services;

public class PaymentPricingService : IPaymentPricingService
{
    private readonly ApplicationDbContext _context;

    public PaymentPricingService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<decimal> CalculateTicketAmountAsync(int userId, int ticketTypeId, int zoneId, DateTime validFrom)
    {
        var now = DateTime.UtcNow;
        var activeSubscription = await _context.Subscriptions
            .Include(s => s.SubscriptionPackage)
            .Where(s => s.UserId == userId
                && s.Status.ToLower() == SubscriptionStatuses.Active
                && s.StartDate <= now
                && s.EndDate >= now)
            .OrderByDescending(s => s.StartDate)
            .ThenByDescending(s => s.EndDate)
            .FirstOrDefaultAsync();

        if (activeSubscription?.SubscriptionPackage != null)
        {
            var zone = await _context.Zones.FindAsync(zoneId);
            if (ZoneCoverage.SubscriptionCoversZone(activeSubscription.SubscriptionPackage, zone))
            {
                return 0;
            }
        }

        var ticketValidFrom = DateTime.SpecifyKind(validFrom, DateTimeKind.Utc).ToUniversalTime();
        var ticketValidFromDate = ticketValidFrom.Date;
        var dayStart = ticketValidFromDate;
        var dayEnd = ticketValidFromDate.AddDays(1).AddTicks(-1);

        var ticketPrice = await _context.TicketPrices
            .Where(tp => tp.TicketTypeId == ticketTypeId
                && tp.ZoneId == zoneId
                && tp.IsActive)
            .Where(tp => tp.ValidFrom <= dayEnd && (!tp.ValidTo.HasValue || tp.ValidTo.Value >= dayStart))
            .OrderByDescending(tp => tp.ValidFrom)
            .FirstOrDefaultAsync();

        if (ticketPrice == null)
        {
            throw new InvalidOperationException("Ticket price not found for the selected ticket type and zone");
        }

        return ticketPrice.Price;
    }

    public async Task<decimal> CalculateSubscriptionAmountAsync(string packageKey)
    {
        var normalized = (packageKey ?? string.Empty).Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new ArgumentException("Invalid package key");
        }

        var package = await _context.SubscriptionPackages
            .Where(p => p.IsActive)
            .Where(p => p.Key.ToLower() == normalized || p.DisplayName.ToLower() == normalized)
            .FirstOrDefaultAsync();

        if (package == null)
        {
            throw new ArgumentException("Invalid package key");
        }

        return package.Price;
    }
}
