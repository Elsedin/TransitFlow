using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreatePayPalOrderRequest
{
    [Required]
    [Range(0.5, 1000000.0, ErrorMessage = "Amount must be greater than 0.5")]
    public decimal Amount { get; set; }

    [MaxLength(3)]
    public string? Currency { get; set; } = "BAM";
}
