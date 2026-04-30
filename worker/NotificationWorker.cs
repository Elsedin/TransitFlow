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
    private const string RoutingKey = "notification.created";
    private const string DeadLetterExchangeName = "transitflow_notifications_dlx";
    private const string DeadLetterQueueName = "notification_dead_letter_queue";
    private const string RetryExchangeName = "transitflow_notifications_retry";
    private const string RetryQueueName = "notification_retry_queue";
    private const string DeadLetterRoutingKey = "notification.dead";
    private const int MaxRetryCount = 5;

    public NotificationWorker(IConfiguration configuration, ILogger<NotificationWorker> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
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
            Password = password,
            DispatchConsumersAsync = true,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(5),
            RequestedHeartbeat = TimeSpan.FromSeconds(30)
        };

        var attempt = 0;
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                attempt++;
                EnsureConnection(factory);
                EnsureTopology();

                try
                {
                    ConsumeLoop(stoppingToken);
                    attempt = 0;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Worker consume loop failed, will reconnect");
                    SafeClose();
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                SafeClose();
                var delay = GetReconnectDelay(attempt);
                _logger.LogWarning(ex, "RabbitMQ connection error (attempt {Attempt}). Retrying in {DelaySeconds}s", attempt, delay.TotalSeconds);
                await Task.Delay(delay, stoppingToken);
            }
        }
    }

    private void EnsureConnection(ConnectionFactory factory)
    {
        if (_connection is { IsOpen: true } && _channel is { IsOpen: true })
            return;

        SafeClose();

        _connection = factory.CreateConnection();
        _connection.ConnectionShutdown += (_, args) =>
        {
            _logger.LogWarning("RabbitMQ connection shutdown: {ReplyCode} {ReplyText}", args.ReplyCode, args.ReplyText);
        };

        _channel = _connection.CreateModel();
    }

    private void EnsureTopology()
    {
        if (_channel == null)
            throw new InvalidOperationException("Channel not initialized");

        _channel.ExchangeDeclare(exchange: ExchangeName, type: ExchangeType.Direct, durable: true);

        _channel.ExchangeDeclare(exchange: DeadLetterExchangeName, type: ExchangeType.Direct, durable: true);
        _channel.QueueDeclare(queue: DeadLetterQueueName, durable: true, exclusive: false, autoDelete: false);
        _channel.QueueBind(queue: DeadLetterQueueName, exchange: DeadLetterExchangeName, routingKey: DeadLetterRoutingKey);

        _channel.ExchangeDeclare(exchange: RetryExchangeName, type: ExchangeType.Direct, durable: true);
        _channel.QueueDeclare(
            queue: RetryQueueName,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: new Dictionary<string, object>
            {
                ["x-dead-letter-exchange"] = ExchangeName,
                ["x-dead-letter-routing-key"] = RoutingKey
            });
        _channel.QueueBind(queue: RetryQueueName, exchange: RetryExchangeName, routingKey: RoutingKey);

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
        _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: RoutingKey);

        _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);
    }

    private void ConsumeLoop(CancellationToken stoppingToken)
    {
        if (_channel == null)
            throw new InvalidOperationException("Channel not initialized");

        var channel = _channel;
        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.Received += async (_, ea) => await OnMessageAsync(channel, ea, stoppingToken);

        channel.BasicConsume(queue: QueueName, autoAck: false, consumer: consumer);
        _logger.LogInformation("Notification worker started and waiting for messages");

        while (!stoppingToken.IsCancellationRequested && channel.IsOpen && _connection is { IsOpen: true })
        {
            Thread.Sleep(500);
        }
    }

    private async Task OnMessageAsync(IModel channel, BasicDeliverEventArgs ea, CancellationToken stoppingToken)
    {
        var body = ea.Body.ToArray();
        var message = Encoding.UTF8.GetString(body);

        try
        {
            await ProcessNotificationAsync(message);
            channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
        }
        catch (Exception ex)
        {
            var currentRetry = GetRetryCount(ea.BasicProperties);
            _logger.LogError(ex, "Error processing RabbitMQ message (retry {Retry}/{Max})", currentRetry, MaxRetryCount);

            if (currentRetry >= MaxRetryCount)
            {
                channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: false);
                return;
            }

            PublishToRetryQueue(channel, ea, message, currentRetry + 1);
            channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
        }
    }

    private static int GetRetryCount(IBasicProperties? props)
    {
        if (props?.Headers == null) return 0;
        if (!props.Headers.TryGetValue("x-retry-count", out var raw)) return 0;

        return raw switch
        {
            byte[] bytes when int.TryParse(Encoding.UTF8.GetString(bytes), out var n) => n,
            int n => n,
            long n => (int)n,
            _ => 0
        };
    }

    private static string GetRetryDelayMs(int retryCount)
    {
        // 5s, 10s, 20s, 40s, 60s...
        var seconds = retryCount switch
        {
            <= 1 => 5,
            2 => 10,
            3 => 20,
            4 => 40,
            _ => 60
        };
        return TimeSpan.FromSeconds(seconds).TotalMilliseconds.ToString("0");
    }

    private void PublishToRetryQueue(IModel channel, BasicDeliverEventArgs ea, string message, int retryCount)
    {
        var props = channel.CreateBasicProperties();
        props.Persistent = true;
        props.ContentType = "application/json";
        props.Headers = new Dictionary<string, object>
        {
            ["x-retry-count"] = retryCount.ToString()
        };
        props.Expiration = GetRetryDelayMs(retryCount);

        channel.BasicPublish(
            exchange: RetryExchangeName,
            routingKey: RoutingKey,
            basicProperties: props,
            body: Encoding.UTF8.GetBytes(message));
    }

    private static TimeSpan GetReconnectDelay(int attempt)
    {
        var seconds = Math.Min(60, Math.Pow(2, Math.Min(attempt, 6)));
        var jitterMs = Random.Shared.Next(0, 500);
        return TimeSpan.FromSeconds(seconds) + TimeSpan.FromMilliseconds(jitterMs);
    }

    private void SafeClose()
    {
        try { _channel?.Close(); } catch { }
        try { _channel?.Dispose(); } catch { }
        _channel = null;

        try { _connection?.Close(); } catch { }
        try { _connection?.Dispose(); } catch { }
        _connection = null;
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
        SafeClose();
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
