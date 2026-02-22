namespace TransitFlow.API.DTOs;

public class TicketPriceDto
{
    public int Id { get; set; }
    public int TicketTypeId { get; set; }
    public string TicketTypeName { get; set; } = string.Empty;
    public int ZoneId { get; set; }
    public string ZoneName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int ValidityDays { get; set; }
    public string ValidityDescription { get; set; } = string.Empty;
    public DateTime ValidFrom { get; set; }
    public DateTime? ValidTo { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsActive { get; set; }
}
