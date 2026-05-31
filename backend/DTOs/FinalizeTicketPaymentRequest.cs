using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class FinalizeTicketPaymentRequest
{
    [Required]
    public string PaymentIntentId { get; set; } = string.Empty;

    [Required]
    public int TicketTypeId { get; set; }

    [Required]
    public int RouteId { get; set; }

    [Required]
    public int ZoneId { get; set; }

    [Required]
    public DateTime ValidFrom { get; set; }
}
