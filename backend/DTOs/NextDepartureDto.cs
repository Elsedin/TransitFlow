namespace TransitFlow.API.DTOs;

public class NextDepartureDto
{
    public int RouteId { get; set; }
    public int DayOfWeek { get; set; }
    public string DayOfWeekName { get; set; } = string.Empty;
    public string DepartureTime { get; set; } = string.Empty;
    public string ArrivalTime { get; set; } = string.Empty;
    public int MinutesUntilDeparture { get; set; }
}

