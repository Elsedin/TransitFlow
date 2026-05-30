namespace TransitFlow.API.Constants;

public static class SubscriptionStatuses
{
    public const string Active = "active";
    public const string Cancelled = "cancelled";
    public const string Expired = "expired";
    public const string Deleted = "deleted";

    public static bool Is(string? status, string expected) =>
        string.Equals(status, expected, StringComparison.OrdinalIgnoreCase);

    public static bool IsKnown(string? status) =>
        Is(status, Active) ||
        Is(status, Cancelled) ||
        Is(status, Expired) ||
        Is(status, Deleted);

    public static string Normalize(string status)
    {
        if (Is(status, Active)) return Active;
        if (Is(status, Cancelled)) return Cancelled;
        if (Is(status, Expired)) return Expired;
        if (Is(status, Deleted)) return Deleted;

        throw new InvalidOperationException("Nepoznat status pretplate");
    }

    public static void EnsureAdminTransition(string currentStatus, string nextStatus)
    {
        var current = Normalize(currentStatus);
        var next = Normalize(nextStatus);

        if (current == Deleted)
        {
            throw new InvalidOperationException("Obrisana pretplata se ne može mijenjati");
        }

        if (current == Cancelled && next == Active)
        {
            throw new InvalidOperationException("Otkazana pretplata se ne može ponovo aktivirati");
        }
    }

    public static void EnsureCanCancel(string? status, DateTime endDate, DateTime now)
    {
        if (!Is(status, Active) || endDate < now)
        {
            throw new InvalidOperationException("Samo aktivna pretplata se može otkazati");
        }
    }
}
