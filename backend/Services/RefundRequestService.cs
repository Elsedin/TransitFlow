using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Stripe;
using System.Text;
using System.Text.Json;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using TransitFlow.API.Models;

namespace TransitFlow.API.Services;

public class RefundRequestService : IRefundRequestService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly IRabbitMQService _rabbitMQService;

    public RefundRequestService(ApplicationDbContext context, IConfiguration configuration, IRabbitMQService rabbitMQService)
    {
        _context = context;
        _configuration = configuration;
        _rabbitMQService = rabbitMQService;
    }

    public async Task<RefundRequestDto> CreateAsync(int userId, CreateRefundRequestDto dto)
    {
        var ticket = await _context.Tickets
            .Include(t => t.Transaction)
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == dto.TicketId);

        if (ticket == null)
            throw new InvalidOperationException("Karta nije pronađena.");

        if (ticket.UserId != userId)
            throw new InvalidOperationException("Nemate pravo na ovu kartu.");

        if (ticket.IsRefunded)
            throw new InvalidOperationException("Karta je već refundovana.");

        if (ticket.IsUsed || ticket.UsedAt.HasValue)
            throw new InvalidOperationException("Refund nije moguć jer je karta već validirana na kontroli.");

        var now = DateTime.UtcNow;
        if (ticket.ValidTo < now)
            throw new InvalidOperationException("Refund nije moguć jer je karta istekla.");

        if (ticket.TransactionId == null || ticket.Transaction == null)
            throw new InvalidOperationException("Refund nije moguć jer karta nema transakciju.");

        if (!string.Equals(ticket.Transaction.Status, "completed", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Refund nije moguć jer transakcija nije završena.");

        var exists = await _context.RefundRequests.AnyAsync(r =>
            r.TicketId == ticket.Id && r.Status == "pending");
        if (exists)
            throw new InvalidOperationException("Već postoji aktivan zahtjev za refund za ovu kartu.");

        var request = new RefundRequest
        {
            UserId = userId,
            TicketId = ticket.Id,
            Message = dto.Message.Trim(),
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        _context.RefundRequests.Add(request);
        await _context.SaveChangesAsync();

        return await MapAsync(request.Id);
    }

    public async Task<List<RefundRequestDto>> GetMyAsync(int userId)
    {
        var items = await _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return items.Select(Map).ToList();
    }

    public async Task<PagedResultDto<RefundRequestDto>> GetMyPagedAsync(int userId, int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
            .Where(r => r.UserId == userId);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<RefundRequestDto>
        {
            Items = items.Select(Map).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<RefundRequestDto>> GetAllAsync(string? status = null)
    {
        var query = BuildFilteredQuery(status);
        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return items.Select(Map).ToList();
    }

    public async Task<PagedResultDto<RefundRequestDto>> GetPagedAsync(int page, int pageSize, string? status = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var query = BuildFilteredQuery(status);
        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResultDto<RefundRequestDto>
        {
            Items = items.Select(Map).ToList(),
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<RefundRequestDto> ApproveAsync(int adminId, int requestId, ResolveRefundRequestDto dto)
    {
        var request = await _context.RefundRequests
            .Include(r => r.Ticket)
                .ThenInclude(t => t!.Transaction)
            .FirstOrDefaultAsync(r => r.Id == requestId);

        if (request == null)
            throw new InvalidOperationException("Zahtjev nije pronađen.");

        if (request.Status != "pending")
            throw new InvalidOperationException("Zahtjev je već obrađen.");

        var ticket = request.Ticket ?? throw new InvalidOperationException("Karta nije pronađena.");

        if (ticket.IsRefunded)
            throw new InvalidOperationException("Karta je već refundovana.");

        if (ticket.IsUsed || ticket.UsedAt.HasValue)
            throw new InvalidOperationException("Refund nije moguć jer je karta već validirana na kontroli.");

        var now = DateTime.UtcNow;
        if (ticket.ValidTo < now)
            throw new InvalidOperationException("Refund nije moguć jer je karta istekla.");

        var transaction = ticket.Transaction ?? throw new InvalidOperationException("Transakcija nije pronađena.");
        if (!string.Equals(transaction.Status, "completed", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Refund nije moguć jer transakcija nije završena.");

        if (transaction.RefundStatus == "refunded")
            throw new InvalidOperationException("Transakcija je već refundovana.");

        transaction.RefundStatus = "pending";
        transaction.RefundReason = dto.AdminNote?.Trim();
        await _context.SaveChangesAsync();

        var refundExternalId = await ExecuteProviderRefundAsync(transaction);

        transaction.RefundStatus = "refunded";
        transaction.RefundedAt = DateTime.UtcNow;
        transaction.ExternalRefundId = refundExternalId;
        transaction.RefundReason = dto.AdminNote?.Trim();

        ticket.IsRefunded = true;
        ticket.RefundedAt = transaction.RefundedAt;

        request.Status = "approved";
        request.ResolvedAt = transaction.RefundedAt;
        request.ResolvedByAdminId = adminId;
        request.AdminNote = dto.AdminNote?.Trim();

        var notification = new Notification
        {
            UserId = request.UserId,
            Title = "Refund odobren",
            Message = $"Vaš zahtjev za refund za kartu #{ticket.TicketNumber} je odobren."
                      + (string.IsNullOrWhiteSpace(request.AdminNote) ? "" : $" Napomena: {request.AdminNote}"),
            Type = "refund_approved",
            IsRead = false,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };
        _context.Notifications.Add(notification);

        await _context.SaveChangesAsync();

        var email = await _context.Users
            .Where(u => u.Id == request.UserId)
            .Select(u => u.Email)
            .FirstOrDefaultAsync();

        _rabbitMQService.PublishNotificationCreated(
            notification.Id,
            notification.Title,
            notification.Message,
            notification.Type,
            notification.UserId,
            email);

        return await MapAsync(request.Id);
    }

    public async Task<RefundRequestDto> RejectAsync(int adminId, int requestId, ResolveRefundRequestDto dto)
    {
        var request = await _context.RefundRequests
            .Include(r => r.Ticket)
            .FirstOrDefaultAsync(r => r.Id == requestId);

        if (request == null)
            throw new InvalidOperationException("Zahtjev nije pronađen.");

        if (request.Status != "pending")
            throw new InvalidOperationException("Zahtjev je već obrađen.");

        request.Status = "rejected";
        request.ResolvedAt = DateTime.UtcNow;
        request.ResolvedByAdminId = adminId;
        request.AdminNote = dto.AdminNote?.Trim();

        var notification = new Notification
        {
            UserId = request.UserId,
            Title = "Refund odbijen",
            Message = $"Zahtjev za refund za kartu #{request.Ticket?.TicketNumber ?? request.TicketId.ToString()} je odbijen."
                      + (string.IsNullOrWhiteSpace(request.AdminNote) ? "" : $" Razlog: {request.AdminNote}"),
            Type = "info",
            IsRead = false,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };
        _context.Notifications.Add(notification);

        await _context.SaveChangesAsync();

        var email = await _context.Users
            .Where(u => u.Id == request.UserId)
            .Select(u => u.Email)
            .FirstOrDefaultAsync();

        _rabbitMQService.PublishNotificationCreated(
            notification.Id,
            notification.Title,
            notification.Message,
            notification.Type,
            notification.UserId,
            email);

        return await MapAsync(request.Id);
    }

    private async Task<string> ExecuteProviderRefundAsync(Models.Transaction transaction)
    {
        if (string.Equals(transaction.PaymentMethod, "Seed", StringComparison.OrdinalIgnoreCase))
        {
            return "seed-refund";
        }

        if (string.Equals(transaction.PaymentMethod, "Stripe", StringComparison.OrdinalIgnoreCase))
        {
            var stripeSecretKey = _configuration["Stripe:SecretKey"];
            if (string.IsNullOrEmpty(stripeSecretKey))
                throw new InvalidOperationException("Stripe Secret Key not configured");

            if (string.IsNullOrWhiteSpace(transaction.ExternalTransactionId))
                throw new InvalidOperationException("Stripe PaymentIntentId not found for transaction");

            StripeConfiguration.ApiKey = stripeSecretKey;

            var piService = new PaymentIntentService();
            var pi = await piService.GetAsync(transaction.ExternalTransactionId);
            var chargeId = pi.LatestChargeId ?? pi.LatestCharge?.Id;
            if (string.IsNullOrWhiteSpace(chargeId))
                throw new InvalidOperationException("Stripe charge id not found for payment intent");

            var refundService = new RefundService();
            var refund = await refundService.CreateAsync(new RefundCreateOptions
            {
                Charge = chargeId,
                Reason = "requested_by_customer"
            });

            return refund.Id;
        }

        if (string.Equals(transaction.PaymentMethod, "PayPal", StringComparison.OrdinalIgnoreCase))
        {
            var clientId = _configuration["PayPal:ClientId"];
            var clientSecret = _configuration["PayPal:ClientSecret"];
            var isSandbox = _configuration["PayPal:IsSandbox"]?.ToLower() == "true";
            if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(clientSecret))
                throw new InvalidOperationException("PayPal credentials not configured");

            var baseUrl = isSandbox ? "https://api.sandbox.paypal.com" : "https://api.paypal.com";

            using var httpClient = new HttpClient();
            var accessToken = await GetPayPalAccessTokenAsync(httpClient, baseUrl, clientId, clientSecret);

            httpClient.DefaultRequestHeaders.Clear();
            httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {accessToken}");
            httpClient.DefaultRequestHeaders.Add("Accept", "application/json");

            if (string.IsNullOrWhiteSpace(transaction.PayPalCaptureId))
            {
                if (string.IsNullOrWhiteSpace(transaction.ExternalTransactionId))
                    throw new InvalidOperationException("PayPal order id not found for transaction");

                var orderResponse = await httpClient.GetAsync($"{baseUrl}/v2/checkout/orders/{transaction.ExternalTransactionId}");
                var orderContent = await orderResponse.Content.ReadAsStringAsync();
                if (!orderResponse.IsSuccessStatusCode)
                {
                    throw new InvalidOperationException($"PayPal order details fetch failed (Status: {orderResponse.StatusCode}): {orderContent}");
                }
                if (orderResponse.IsSuccessStatusCode)
                {
                    try
                    {
                        var orderData = JsonSerializer.Deserialize<JsonElement>(orderContent);
                        var captureId = ExtractFirstPayPalCaptureId(orderData);
                        if (!string.IsNullOrWhiteSpace(captureId))
                        {
                            transaction.PayPalCaptureId = captureId;
                            await _context.SaveChangesAsync();
                        }
                    }
                    catch
                    {
                    }
                }
            }

            if (string.IsNullOrWhiteSpace(transaction.PayPalCaptureId))
            {
                if (isSandbox)
                {
                    return "paypal-sandbox-refund";
                }
                throw new InvalidOperationException("PayPal capture id not found for transaction");
            }

            var refundRequest = new HttpRequestMessage(
                HttpMethod.Post,
                $"{baseUrl}/v2/payments/captures/{transaction.PayPalCaptureId}/refund");
            refundRequest.Headers.Add("Prefer", "return=representation");
            refundRequest.Content = new StringContent("{}", Encoding.UTF8, "application/json");

            var response = await httpClient.SendAsync(refundRequest);
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new InvalidOperationException($"PayPal refund failed (Status: {response.StatusCode}): {responseContent}");

            try
            {
                var data = JsonSerializer.Deserialize<JsonElement>(responseContent);
                return data.GetProperty("id").GetString() ?? "paypal-refund";
            }
            catch
            {
                return "paypal-refund";
            }
        }

        throw new InvalidOperationException("Unsupported payment method for refund");
    }

    private IQueryable<RefundRequest> BuildFilteredQuery(string? status)
    {
        var query = _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(r => r.Status == status);
        }

        return query;
    }

    private static string? ExtractFirstPayPalCaptureId(JsonElement root)
    {
        try
        {
            if (root.ValueKind == JsonValueKind.Object)
            {
                if (root.TryGetProperty("purchase_units", out var purchaseUnits) &&
                    purchaseUnits.ValueKind == JsonValueKind.Array &&
                    purchaseUnits.GetArrayLength() > 0)
                {
                    var pu0 = purchaseUnits[0];
                    if (pu0.ValueKind == JsonValueKind.Object &&
                        pu0.TryGetProperty("payments", out var payments) &&
                        payments.ValueKind == JsonValueKind.Object &&
                        payments.TryGetProperty("captures", out var captures) &&
                        captures.ValueKind == JsonValueKind.Array &&
                        captures.GetArrayLength() > 0)
                    {
                        var cap0 = captures[0];
                        if (cap0.ValueKind == JsonValueKind.Object && cap0.TryGetProperty("id", out var idEl))
                        {
                            var id = idEl.GetString();
                            if (!string.IsNullOrWhiteSpace(id)) return id;
                        }
                    }
                }
            }
        }
        catch
        {
        }

        return FindCaptureIdDeep(root);
    }

    private static string? FindCaptureIdDeep(JsonElement el)
    {
        try
        {
            if (el.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in el.EnumerateObject())
                {
                    if (prop.NameEquals("captures") && prop.Value.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var item in prop.Value.EnumerateArray())
                        {
                            if (item.ValueKind == JsonValueKind.Object && item.TryGetProperty("id", out var idEl))
                            {
                                var id = idEl.GetString();
                                if (!string.IsNullOrWhiteSpace(id)) return id;
                            }
                        }
                    }

                    var nested = FindCaptureIdDeep(prop.Value);
                    if (!string.IsNullOrWhiteSpace(nested)) return nested;
                }
            }

            if (el.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in el.EnumerateArray())
                {
                    var nested = FindCaptureIdDeep(item);
                    if (!string.IsNullOrWhiteSpace(nested)) return nested;
                }
            }
        }
        catch
        {
        }

        return null;
    }

    private async Task<string> GetPayPalAccessTokenAsync(HttpClient httpClient, string baseUrl, string clientId, string clientSecret)
    {
        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{clientSecret}"));

        var tokenRequest = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v1/oauth2/token");
        tokenRequest.Headers.Add("Authorization", $"Basic {credentials}");
        tokenRequest.Content = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("grant_type", "client_credentials")
        });

        var response = await httpClient.SendAsync(tokenRequest);
        var content = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"PayPal authentication failed: {content}");

        var tokenData = JsonSerializer.Deserialize<JsonElement>(content);
        return tokenData.GetProperty("access_token").GetString() ?? throw new InvalidOperationException("Failed to get PayPal access token");
    }

    private RefundRequestDto Map(RefundRequest r)
    {
        return new RefundRequestDto
        {
            Id = r.Id,
            UserId = r.UserId,
            UserEmail = r.User?.Email ?? string.Empty,
            TicketId = r.TicketId,
            TicketNumber = r.Ticket?.TicketNumber ?? string.Empty,
            TicketPublicId = r.Ticket?.PublicId ?? Guid.Empty,
            Message = r.Message,
            Status = r.Status,
            CreatedAt = r.CreatedAt,
            ResolvedAt = r.ResolvedAt,
            AdminNote = r.AdminNote
        };
    }

    private async Task<RefundRequestDto> MapAsync(int requestId)
    {
        var r = await _context.RefundRequests
            .Include(x => x.User)
            .Include(x => x.Ticket)
            .FirstAsync(x => x.Id == requestId);
        return Map(r);
    }
}

