using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class PurchaseTicketDto
{
    [Required]
    public int TicketTypeId { get; set; }
    
    [Required]
    public int RouteId { get; set; }
    
    [Required]
    public int ZoneId { get; set; }
    
    [Required]
    public DateTime ValidFrom { get; set; }
    
    [Required]
    public DateTime ValidTo { get; set; }
}
