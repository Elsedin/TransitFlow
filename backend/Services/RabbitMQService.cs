using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace TransitFlow.API.Services;

public class RabbitMQService : IRabbitMQService, IDisposable
{
    private IConnection? _connection;
    private IModel? _channel;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RabbitMQService> _logger;
    private readonly object _lock = new object();
    private const string ExchangeName = "transitflow_notifications";
    private const string QueueName = "notification_queue";
    private const string DeadLetterExchangeName = "transitflow_notifications_dlx";
    private const string DeadLetterRoutingKey = "notification.dead";

    public RabbitMQService(IConfiguration configuration, ILogger<RabbitMQService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    private void EnsureConnection()
    {
        if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
        {
            return;
        }

        lock (_lock)
        {
            if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
            {
                return;
            }

            try
            {
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

                _connection?.Dispose();
                _channel?.Dispose();

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();

                _channel.ExchangeDeclare(exchange: ExchangeName, type: ExchangeType.Direct, durable: true);
                // Must match the queue arguments declared by the worker to avoid
                // PRECONDITION_FAILED (406) when the queue already exists.
                _channel.ExchangeDeclare(exchange: DeadLetterExchangeName, type: ExchangeType.Direct, durable: true);
                _channel.QueueDeclare(
                    queue: QueueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: new Dictionary<string, object>
                    {
                        ["x-dead-letter-exchange"] = DeadLetterExchangeName,
                        ["x-dead-letter-routing-key"] = DeadLetterRoutingKey
                    });
                _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "notification.created");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to connect to RabbitMQ");
                throw;
            }
        }
    }

    public void PublishNotificationCreated(int notificationId, string title, string message, string type, int? userId)
    {
        try
        {
            EnsureConnection();
            
            var notificationEvent = new
            {
                NotificationId = notificationId,
                Title = title,
                Message = message,
                Type = type,
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(notificationEvent));

            var properties = _channel!.CreateBasicProperties();
            properties.Persistent = true;

            _channel.BasicPublish(
                exchange: ExchangeName,
                routingKey: "notification.created",
                basicProperties: properties,
                body: body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish notification");
        }
    }

    public void PublishNotificationBroadcast(int notificationId, string title, string message, string type)
    {
        try
        {
            EnsureConnection();
            
            var notificationEvent = new
            {
                NotificationId = notificationId,
                Title = title,
                Message = message,
                Type = type,
                IsBroadcast = true,
                CreatedAt = DateTime.UtcNow
            };

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(notificationEvent));

            var properties = _channel!.CreateBasicProperties();
            properties.Persistent = true;

            _channel.BasicPublish(
                exchange: ExchangeName,
                routingKey: "notification.created",
                basicProperties: properties,
                body: body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish broadcast notification");
        }
    }

    public void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
    }
}
