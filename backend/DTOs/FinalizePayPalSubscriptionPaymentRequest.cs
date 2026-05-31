using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class FinalizePayPalSubscriptionPaymentRequest
{
    [Required]
    public string OrderId { get; set; } = string.Empty;

    [Required]
    public string PackageKey { get; set; } = string.Empty;
}
