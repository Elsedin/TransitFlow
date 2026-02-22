namespace TransitFlow.API.DTOs;

public class CityDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public int? CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
