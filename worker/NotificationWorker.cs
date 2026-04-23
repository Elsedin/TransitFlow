using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace TransitFlow.Worker;

public class NotificationWorker : BackgroundService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<NotificationWorker> _logger;
    private IConnection? _connection;
    private IModel? _channel;
    private const string ExchangeName = "transitflow_notifications";
    private const string QueueName = "notification_queue";

    public NotificationWorker(IConfiguration configuration, ILogger<NotificationWorker> logger)
    {
        _configuration = configuration;
        _logger = logger;
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
                    _logger.LogError(ex, "Error processing RabbitMQ message");
                    _channel?.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
                }
            };

            _channel.BasicConsume(queue: QueueName, autoAck: false, consumer: consumer);

            _logger.LogInformation("Notification worker started and waiting for messages");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RabbitMQ connection error");
        }
    }

    private async Task ProcessNotificationAsync(string message)
    {
        try
        {
            var notificationEvent = JsonSerializer.Deserialize<NotificationEvent>(message);
            
            if (notificationEvent == null)
            {
                _logger.LogWarning("Failed to deserialize notification event");
                return;
            }

            _logger.LogInformation(
                "Processing notification {NotificationId} ({Title})",
                notificationEvent.NotificationId,
                notificationEvent.Title);

            await SendEmailNotificationAsync(notificationEvent);
            await LogNotificationAsync(notificationEvent);

            _logger.LogInformation("Processed notification {NotificationId}", notificationEvent.NotificationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing notification");
            throw;
        }
    }

    private async Task SendEmailNotificationAsync(NotificationEvent notificationEvent)
    {
        await Task.Delay(100);

        _logger.LogInformation("Email notification sent for notification {NotificationId}", notificationEvent.NotificationId);
    }

    private async Task LogNotificationAsync(NotificationEvent notificationEvent)
    {
        await Task.Delay(50);

        _logger.LogInformation(
            "Notification created: {NotificationId} ({Title}) Type={Type} UserId={UserId}",
            notificationEvent.NotificationId,
            notificationEvent.Title,
            notificationEvent.Type,
            notificationEvent.UserId?.ToString() ?? "Broadcast");
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
