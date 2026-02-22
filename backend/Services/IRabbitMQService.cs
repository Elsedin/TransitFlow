namespace TransitFlow.API.Services;

public interface IRabbitMQService
{
    void PublishNotificationCreated(int notificationId, string title, string message, string type, int? userId);
    void PublishNotificationBroadcast(int notificationId, string title, string message, string type);
    void Dispose();
}
