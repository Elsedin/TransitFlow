using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class RecoverPurchaseRequest
{
    [Required]
    public int TransactionId { get; set; }

    [Required]
    public string PurchaseType { get; set; } = string.Empty;

    public int? TicketTypeId { get; set; }

    public int? RouteId { get; set; }

    public int? ZoneId { get; set; }

    public DateTime? ValidFrom { get; set; }

    public string? PackageKey { get; set; }
}
