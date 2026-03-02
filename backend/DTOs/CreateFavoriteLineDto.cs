using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateFavoriteLineDto
{
    [Required]
    public int TransportLineId { get; set; }
}
