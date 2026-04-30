using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateRefundRequestDto
{
    [Required]
    public int TicketId { get; set; }

    [Required]
    [MaxLength(1000)]
    public string Message { get; set; } = string.Empty;
}

