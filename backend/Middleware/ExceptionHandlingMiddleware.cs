using System.Net;
using System.Runtime.ExceptionServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Http.Extensions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace TransitFlow.API.Middleware;

public sealed class ExceptionHandlingMiddleware
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task Invoke(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        if (context.Response.HasStarted)
        {
            ExceptionDispatchInfo.Capture(exception).Throw();
        }

        var traceId = context.TraceIdentifier;

        var (statusCode, title) = exception switch
        {
            UnauthorizedAccessException => (HttpStatusCode.Forbidden, "Forbidden"),
            KeyNotFoundException => (HttpStatusCode.NotFound, "Not found"),
            InvalidOperationException => (HttpStatusCode.BadRequest, "Bad request"),
            _ => (HttpStatusCode.InternalServerError, "Server error")
        };

        var logLevel = statusCode == HttpStatusCode.InternalServerError ? LogLevel.Error : LogLevel.Warning;
        _logger.Log(logLevel, exception, "Unhandled exception. TraceId={TraceId} Method={Method} Path={Path}",
            traceId,
            context.Request.Method,
            context.Request.GetEncodedPathAndQuery());

        var body = new ProblemDetailsBody
        {
            Type = "about:blank",
            Title = title,
            Status = (int)statusCode,
            Detail = _environment.IsDevelopment() ? exception.ToString() : null,
            TraceId = traceId
        };

        context.Response.Clear();
        context.Response.StatusCode = body.Status ?? (int)HttpStatusCode.InternalServerError;
        context.Response.ContentType = "application/problem+json; charset=utf-8";

        await context.Response.WriteAsync(JsonSerializer.Serialize(body, JsonOptions));
    }

    private sealed class ProblemDetailsBody
    {
        public string? Type { get; set; }
        public string? Title { get; set; }
        public int? Status { get; set; }
        public string? Detail { get; set; }
        public string? TraceId { get; set; }
    }
}
