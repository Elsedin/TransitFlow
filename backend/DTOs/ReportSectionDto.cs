namespace TransitFlow.API.DTOs;

public class ReportSectionDto
{
    public string Title { get; set; } = string.Empty;
    public List<string> Columns { get; set; } = new();
    public List<List<string>> Rows { get; set; } = new();
}

