using System.ComponentModel.DataAnnotations;

namespace TransitFlow.API.DTOs;

public class CreateScheduleDto
{
    [Required]
    public int RouteId { get; set; }
    
    [Required]
    public int VehicleId { get; set; }
    
    [Required]
    public string DepartureTime { get; set; } = string.Empty;
    
    [Required]
    public string ArrivalTime { get; set; } = string.Empty;
    
    [Required]
    [Range(0, 6)]
    public int DayOfWeek { get; set; }
}
