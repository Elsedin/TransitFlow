using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CancelSubscriptionDto
{
    [Required]
    [MaxLength(500)]
    public string Reason { get; set; } = string.Empty;
}
