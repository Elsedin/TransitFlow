namespace TransitFlow.API.DTOs;

public class ReportRequestDto
{
    public string ReportType { get; set; } = "ticket_sales";
    public string? Period { get; set; }
    public DateTime? DateFrom { get; set; }
    public DateTime? DateTo { get; set; }
    public int? TransportLineId { get; set; }
    public int? TicketTypeId { get; set; }
}
