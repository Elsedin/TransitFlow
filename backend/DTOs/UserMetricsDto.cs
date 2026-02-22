namespace TransitFlow.API.DTOs;

public class UserMetricsDto
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int NewUsersThisMonth { get; set; }
    public int BlockedUsers { get; set; }
}
