namespace TransitFlow.API.DTOs;

public class SubscriptionMetricsDto
{
    public int TotalSubscriptions { get; set; }
    public int ActiveSubscriptions { get; set; }
    public int ExpiredSubscriptions { get; set; }
    public int NewSubscriptionsThisMonth { get; set; }
    public decimal TotalRevenue { get; set; }
}
