namespace TransitFlow.API.DTOs;

public class SubscriptionPackageDto
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int DurationDays { get; set; }
    public decimal Price { get; set; }
    public int MaxZoneId { get; set; }
    public bool IsActive { get; set; }
}
