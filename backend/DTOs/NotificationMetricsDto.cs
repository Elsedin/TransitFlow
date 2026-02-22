namespace TransitFlow.API.DTOs;

public class NotificationMetricsDto
{
    public int TotalNotifications { get; set; }
    public int UnreadNotifications { get; set; }
    public int ReadNotifications { get; set; }
    public int ActiveNotifications { get; set; }
    public Dictionary<string, int> NotificationsByType { get; set; } = new();
    public int BroadcastNotifications { get; set; }
    public int UserSpecificNotifications { get; set; }
}
