using System.Text.RegularExpressions;
using TransitFlow.API.Models;

namespace TransitFlow.API.Services;

public static class ZoneCoverage
{
    private static readonly Regex ZoneLevelPattern = new(@"Zona\s*(\d+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

    public static int ResolveZoneLevel(Zone? zone)
    {
        if (zone == null)
        {
            return 0;
        }

        if (zone.Level > 0)
        {
            return zone.Level;
        }

        var match = ZoneLevelPattern.Match(zone.Name);
        if (match.Success && int.TryParse(match.Groups[1].Value, out var parsed))
        {
            return parsed;
        }

        return 0;
    }

    public static bool SubscriptionCoversZone(SubscriptionPackage? package, Zone? zone)
    {
        if (package == null || zone == null || !package.IsActive)
        {
            return false;
        }

        var zoneLevel = ResolveZoneLevel(zone);
        if (zoneLevel <= 0)
        {
            return false;
        }

        return package.MaxZoneLevel >= zoneLevel;
    }
}
