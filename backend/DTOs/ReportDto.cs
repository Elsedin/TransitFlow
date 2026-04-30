namespace TransitFlow.API.DTOs;

public class ReportDto
{
    public string ReportType { get; set; } = string.Empty;
    public string ReportTitle { get; set; } = string.Empty;
    public DateTime? DateFrom { get; set; }
    public DateTime? DateTo { get; set; }
    public ReportSummaryDto Summary { get; set; } = new();
    public List<ReportByTicketTypeDto> SalesByTicketType { get; set; } = new();
    public List<ReportSummaryItemDto> SummaryItems { get; set; } = new();
    public List<ReportSectionDto> Sections { get; set; } = new();
}
