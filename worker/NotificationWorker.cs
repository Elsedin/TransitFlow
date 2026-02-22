using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace TransitFlow.Worker;

public class NotificationWorker : BackgroundService
{
    private readonly IConfiguration _configuration;
    private IConnection? _connection;
    private IModel? _channel;
    private const string ExchangeName = "transitflow_notifications";
    private const string QueueName = "notification_queue";

    public NotificationWorker(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(5000, stoppingToken);

        var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
        var port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672");
        var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
        var password = _configuration["RabbitMQ:Password"] ?? "guest";

        var factory = new ConnectionFactory
        {
            HostName = hostName,
            Port = port,
            UserName = userName,
            Password = password
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            _channel.ExchangeDeclare(exchange: ExchangeName, type: ExchangeType.Direct, durable: true);
            _channel.QueueDeclare(queue: QueueName, durable: true, exclusive: false, autoDelete: false);
            _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "notification.created");

            _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

            var consumer = new EventingBasicConsumer(_channel);
            consumer.Received += async (model, ea) =>
            {
                var body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                
                try
                {
                    await ProcessNotificationAsync(message);
                    _channel?.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[NotificationWorker] Error processing message: {ex.Message}");
                    _channel?.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
                }
            };

            _channel.BasicConsume(queue: QueueName, autoAck: false, consumer: consumer);

            Console.WriteLine("[NotificationWorker] Started and waiting for messages...");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[NotificationWorker] Connection error: {ex.Message}");
        }
    }

    private async Task ProcessNotificationAsync(string message)
    {
        try
        {
            var notificationEvent = JsonSerializer.Deserialize<NotificationEvent>(message);
            
            if (notificationEvent == null)
            {
                Console.WriteLine("[NotificationWorker] Failed to deserialize notification event");
                return;
            }

            Console.WriteLine($"[NotificationWorker] Processing notification: ID={notificationEvent.NotificationId}, Title={notificationEvent.Title}");

            await SendEmailNotificationAsync(notificationEvent);
            await LogNotificationAsync(notificationEvent);

            Console.WriteLine($"[NotificationWorker] Successfully processed notification ID={notificationEvent.NotificationId}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[NotificationWorker] Error processing notification: {ex.Message}");
            throw;
        }
    }

    private async Task SendEmailNotificationAsync(NotificationEvent notificationEvent)
    {
        await Task.Delay(100);

        Console.WriteLine($"[NotificationWorker] Email notification sent for notification ID={notificationEvent.NotificationId}");
    }

    private async Task LogNotificationAsync(NotificationEvent notificationEvent)
    {
        await Task.Delay(50);

        var logMessage = $"[{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}] Notification Created - " +
                         $"ID: {notificationEvent.NotificationId}, " +
                         $"Title: {notificationEvent.Title}, " +
                         $"Type: {notificationEvent.Type}, " +
                         $"UserId: {notificationEvent.UserId?.ToString() ?? "Broadcast"}";

        Console.WriteLine(logMessage);
    }

    public override void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
        base.Dispose();
    }
}

public class NotificationEvent
{
    public int NotificationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public bool IsBroadcast { get; set; }
    public DateTime CreatedAt { get; set; }
}
