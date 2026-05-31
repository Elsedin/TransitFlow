namespace TransitFlow.API.Constants;

public static class RefundRequestStatuses
{
    public const string Pending = "pending";
    public const string Approved = "approved";
    public const string Rejected = "rejected";

    public static bool Is(string? status, string expected) =>
        string.Equals(status, expected, StringComparison.OrdinalIgnoreCase);
}
