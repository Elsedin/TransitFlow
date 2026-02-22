using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace TransitFlow.API.Services;

public class RabbitMQService : IRabbitMQService, IDisposable
{
    private IConnection? _connection;
    private IModel? _channel;
    private readonly IConfiguration _configuration;
    private readonly object _lock = new object();
    private const string ExchangeName = "transitflow_notifications";
    private const string QueueName = "notification_queue";

    public RabbitMQService(IConfiguration configuration)
    {
        _configuration = configuration;
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
                _channel.QueueDeclare(queue: QueueName, durable: true, exclusive: false, autoDelete: false);
                _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "notification.created");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[RabbitMQService] Failed to connect to RabbitMQ: {ex.Message}");
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
            Console.WriteLine($"[RabbitMQService] Failed to publish notification: {ex.Message}");
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
            Console.WriteLine($"[RabbitMQService] Failed to publish broadcast notification: {ex.Message}");
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
