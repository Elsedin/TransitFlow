using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class FinalizeSubscriptionPaymentRequest
{
    [Required]
    public string PaymentIntentId { get; set; } = string.Empty;

    [Required]
    public string PackageKey { get; set; } = string.Empty;
}
