namespace TransitFlow.API.DTOs;

public class CountryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Code { get; set; }
    public bool IsActive { get; set; }
    public int CityCount { get; set; }
}

