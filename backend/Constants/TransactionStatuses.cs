namespace TransitFlow.API.Constants;

public static class TransactionStatuses
{
    public const string Pending = "pending";
    public const string Completed = "completed";
    public const string Failed = "failed";

    public static bool Is(string? status, string expected) =>
        string.Equals(status, expected, StringComparison.OrdinalIgnoreCase);
}
