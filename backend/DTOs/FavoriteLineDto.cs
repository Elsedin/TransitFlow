namespace TransitFlow.API.DTOs;

public class FavoriteLineDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public int TransportLineId { get; set; }
    public string TransportLineNumber { get; set; } = string.Empty;
    public string TransportLineName { get; set; } = string.Empty;
    public string Origin { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string TransportTypeName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
