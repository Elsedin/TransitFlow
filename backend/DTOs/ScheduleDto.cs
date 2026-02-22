namespace TransitFlow.API.DTOs;

public class ScheduleDto
{
    public int Id { get; set; }
    public int RouteId { get; set; }
    public string RouteName { get; set; } = string.Empty;
    public string RouteOrigin { get; set; } = string.Empty;
    public string RouteDestination { get; set; } = string.Empty;
    public int VehicleId { get; set; }
    public string VehicleLicensePlate { get; set; } = string.Empty;
    public string DepartureTime { get; set; } = string.Empty;
    public string ArrivalTime { get; set; } = string.Empty;
    public int DayOfWeek { get; set; }
    public string DayOfWeekName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
