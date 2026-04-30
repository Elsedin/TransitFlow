using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class ResolveRefundRequestDto
{
    [MaxLength(500)]
    public string? AdminNote { get; set; }
}

