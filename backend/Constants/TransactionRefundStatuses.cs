namespace TransitFlow.API.Constants;

public static class TransactionRefundStatuses
{
    public const string None = "none";
    public const string Pending = "pending";
    public const string Refunded = "refunded";

    public static bool Is(string? status, string expected) =>
        string.Equals(status, expected, StringComparison.OrdinalIgnoreCase);
}
