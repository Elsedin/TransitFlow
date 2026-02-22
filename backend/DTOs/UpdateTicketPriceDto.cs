using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class UpdateTicketPriceDto
{
    [Required]
    public int TicketTypeId { get; set; }
    
    [Required]
    public int ZoneId { get; set; }
    
    [Required]
    [Range(0.01, 999999.99)]
    public decimal Price { get; set; }
    
    [Required]
    public DateTime ValidFrom { get; set; }
    
    public DateTime? ValidTo { get; set; }
    
    public bool IsActive { get; set; }
}
