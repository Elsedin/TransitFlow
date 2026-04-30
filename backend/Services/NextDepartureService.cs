using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class NextDepartureService : INextDepartureService
{
    private readonly ApplicationDbContext _context;

    public NextDepartureService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<NextDepartureDto>> GetNextDeparturesAsync(int routeId, int count, DateTimeOffset nowUtc)
    {
        if (count <= 0 || count > 20)
        {
            throw new ArgumentException("Count must be between 1 and 20");
        }

        var routeExists = await _context.Routes.AnyAsync(r => r.Id == routeId && r.IsActive);
        if (!routeExists)
        {
            throw new KeyNotFoundException("Route not found");
        }

        var schedules = await _context.Schedules
            .Where(s => s.RouteId == routeId && s.IsActive)
            .Select(s => new
            {
                s.DayOfWeek,
                s.DepartureTime,
                s.ArrivalTime
            })
            .ToListAsync();

        if (schedules.Count == 0)
        {
            return [];
        }

        var nowLocal = nowUtc.ToLocalTime().DateTime;
        var results = new List<(DateTime departureLocal, DayOfWeek dayOfWeek, TimeOnly departureTime, TimeOnly arrivalTime)>();

        for (var dayOffset = 0; dayOffset < 7 && results.Count < count; dayOffset++)
        {
            var date = nowLocal.Date.AddDays(dayOffset);
            var day = date.DayOfWeek;

            var daySchedules = schedules
                .Where(s => s.DayOfWeek == day)
                .OrderBy(s => s.DepartureTime)
                .ToList();

            foreach (var s in daySchedules)
            {
                var departureLocal = date.Add(s.DepartureTime.ToTimeSpan());
                if (dayOffset == 0 && departureLocal <= nowLocal)
                {
                    continue;
                }

                results.Add((departureLocal, day, s.DepartureTime, s.ArrivalTime));
                if (results.Count >= count)
                {
                    break;
                }
            }
        }

        return results
            .OrderBy(r => r.departureLocal)
            .Take(count)
            .Select(r => new NextDepartureDto
            {
                RouteId = routeId,
                DayOfWeek = (int)r.dayOfWeek,
                DayOfWeekName = GetDayOfWeekName(r.dayOfWeek),
                DepartureTime = r.departureTime.ToString("HH:mm"),
                ArrivalTime = r.arrivalTime.ToString("HH:mm"),
                MinutesUntilDeparture = (int)Math.Max(0, Math.Ceiling((r.departureLocal - nowLocal).TotalMinutes))
            })
            .ToList();
    }

    private static string GetDayOfWeekName(DayOfWeek dayOfWeek)
    {
        return dayOfWeek switch
        {
            DayOfWeek.Monday => "Ponedjeljak",
            DayOfWeek.Tuesday => "Utorak",
            DayOfWeek.Wednesday => "Srijeda",
            DayOfWeek.Thursday => "Četvrtak",
            DayOfWeek.Friday => "Petak",
            DayOfWeek.Saturday => "Subota",
            DayOfWeek.Sunday => "Nedjelja",
            _ => dayOfWeek.ToString()
        };
    }
}

