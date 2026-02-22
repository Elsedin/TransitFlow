namespace TransitFlow.API.DTOs;

public class TicketTypeDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int ValidityDays { get; set; }
    public bool IsActive { get; set; }
}
