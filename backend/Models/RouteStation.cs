using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.Models;

public class RouteStation
{
    [Key]
    public int Id { get; set; }
    
    public int RouteId { get; set; }
    
    public virtual Route? Route { get; set; }
    
    public int StationId { get; set; }
    
    public virtual Station? Station { get; set; }
    
    public int Order { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
