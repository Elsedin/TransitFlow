using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CapturePayPalOrderRequest
{
    [Required]
    public string OrderId { get; set; } = string.Empty;
}
