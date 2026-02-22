namespace TransitFlow.API.DTOs;

public class TransportLineDto
{
    public int Id { get; set; }
    public string LineNumber { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Origin { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string TransportTypeName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
