using TransitFlow.API.Models;

namespace TransitFlow.API.Constants;

public static class TicketStatuses
{
    public const string Active = "Aktivna";
    public const string Used = "Korištena";
    public const string Expired = "Istekla";
    public const string Inactive = "Neaktivna";
    public const string Refunded = "Refundovana";

    public static string Resolve(Ticket ticket, DateTime now)
    {
        if (ticket.IsRefunded)
        {
            return Refunded;
        }

        if (ticket.IsUsed)
        {
            return Used;
        }

        if (ticket.ValidFrom > now)
        {
            return Inactive;
        }

        if (ticket.ValidTo < now)
        {
            return Expired;
        }

        return Active;
    }
}
