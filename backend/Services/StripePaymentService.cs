using System.Text;
using System.Text.Json;
using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Stripe;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;

namespace TransitFlow.API.Services;

public class StripePaymentService : IPaymentService
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;

    public StripePaymentService(IConfiguration configuration, ApplicationDbContext context)
    {
        _configuration = configuration;
        _context = context;
    }

    public async Task<PaymentIntentResponse> CreateStripePaymentIntentAsync(decimal amount, string currency, int userId)
    {
        var stripeSecretKey = _configuration["Stripe:SecretKey"];
        if (string.IsNullOrEmpty(stripeSecretKey))
        {
            throw new InvalidOperationException("Stripe Secret Key not configured");
        }

        StripeConfiguration.ApiKey = stripeSecretKey;

        var options = new PaymentIntentCreateOptions
        {
            Amount = (long)(amount * 100),
            Currency = currency.ToLower(),
            PaymentMethodTypes = new List<string> { "card" },
            Metadata = new Dictionary<string, string>
            {
                { "userId", userId.ToString() }
            }
        };

        var service = new PaymentIntentService();
        var paymentIntent = await service.CreateAsync(options);

        var transactionNumber = GenerateTransactionNumber();

        var transaction = new Models.Transaction
        {
            TransactionNumber = transactionNumber,
            UserId = userId,
            Amount = amount,
            PaymentMethod = "Stripe",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            ExternalTransactionId = paymentIntent.Id,
            Notes = $"PaymentIntent: {paymentIntent.Id}"
        };

        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync();

        return new PaymentIntentResponse
        {
            ClientSecret = paymentIntent.ClientSecret,
            PaymentIntentId = paymentIntent.Id,
            TransactionId = transaction.Id
        };
    }

    public async Task<PaymentResult> ConfirmStripePaymentAsync(string paymentIntentId, int userId)
    {
        var stripeSecretKey = _configuration["Stripe:SecretKey"];
        if (string.IsNullOrEmpty(stripeSecretKey))
        {
            throw new InvalidOperationException("Stripe Secret Key not configured");
        }

        StripeConfiguration.ApiKey = stripeSecretKey;

        var service = new PaymentIntentService();
        var paymentIntent = await service.GetAsync(paymentIntentId);

        if (paymentIntent.Status != "succeeded")
        {
            return new PaymentResult 
            { 
                Success = false, 
                Message = $"Payment status is {paymentIntent.Status}, expected succeeded" 
            };
        }

        var transaction = await _context.Transactions
            .FirstOrDefaultAsync(t =>
                t.UserId == userId &&
                t.PaymentMethod == "Stripe" &&
                t.Status == "pending" &&
                t.ExternalTransactionId == paymentIntentId);

        if (transaction == null)
        {
            return new PaymentResult 
            { 
                Success = false, 
                Message = "Transaction not found" 
            };
        }

        transaction.Status = "completed";
        transaction.CompletedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return new PaymentResult
        {
            Success = true,
            TransactionId = transaction.Id,
            PaymentIntentId = paymentIntentId,
            Message = "Payment confirmed successfully"
        };
    }

    public async Task<PayPalOrderResponse> CreatePayPalOrderAsync(decimal amount, string currency, int userId)
    {
        var clientId = _configuration["PayPal:ClientId"];
        var clientSecret = _configuration["PayPal:ClientSecret"];
        var isSandbox = _configuration["PayPal:IsSandbox"]?.ToLower() == "true";

        if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(clientSecret))
        {
            throw new InvalidOperationException("PayPal credentials not configured");
        }

        var baseUrl = isSandbox 
            ? "https://api.sandbox.paypal.com" 
            : "https://api.paypal.com";

        var httpClient = new HttpClient();

        string accessToken;
        try
        {
            accessToken = await GetPayPalAccessTokenAsync(httpClient, baseUrl, clientId, clientSecret);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"PayPal authentication failed. Please check your PayPal credentials. Error: {ex.Message}");
        }

        var originalAmount = amount;
        var currencyCode = currency.ToUpperInvariant();
        var paypalAmount = amount;
        if (currencyCode == "BAM")
        {
            var bamToUsdRateString = _configuration["PayPal:BamToUsdRate"];
            if (string.IsNullOrWhiteSpace(bamToUsdRateString) ||
                !decimal.TryParse(bamToUsdRateString, NumberStyles.Any, CultureInfo.InvariantCulture, out var bamToUsdRate) ||
                bamToUsdRate <= 0)
            {
                throw new InvalidOperationException("PayPal BAM to USD rate not configured");
            }

            currencyCode = "USD";
            paypalAmount = decimal.Round(amount / bamToUsdRate, 2, MidpointRounding.AwayFromZero);
        }

        if (paypalAmount < 0.01m || paypalAmount > 100000m)
        {
            throw new InvalidOperationException($"PayPal amount {paypalAmount} is out of valid range (0.01 - 100000)");
        }

        var orderRequest = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
                new
                {
                    amount = new
                    {
                        currency_code = currencyCode,
                        value = paypalAmount.ToString("F2", CultureInfo.InvariantCulture)
                    }
                }
            },
            application_context = new
            {
                return_url = "https://transitflow.app/payment/success",
                cancel_url = "https://transitflow.app/payment/cancel",
                shipping_preference = "NO_SHIPPING",
                user_action = "PAY_NOW"
            }
        };

        var requestContent = new StringContent(
            JsonSerializer.Serialize(orderRequest),
            Encoding.UTF8,
            "application/json"
        );

        httpClient.DefaultRequestHeaders.Clear();
        httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {accessToken}");
        httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
        httpClient.DefaultRequestHeaders.Add("Prefer", "return=representation");

        var response = await httpClient.PostAsync($"{baseUrl}/v2/checkout/orders", requestContent);
        var responseContent = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"PayPal order creation failed (Status: {response.StatusCode}): {responseContent}");
        }

        if (string.IsNullOrEmpty(responseContent))
        {
            throw new InvalidOperationException("PayPal API returned empty response");
        }

        JsonElement orderData;
        try
        {
            orderData = JsonSerializer.Deserialize<JsonElement>(responseContent);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to parse PayPal response: {ex.Message}. Response: {responseContent}");
        }
        var orderId = orderData.GetProperty("id").GetString() ?? string.Empty;
        var approvalUrl = orderData.GetProperty("links")
            .EnumerateArray()
            .FirstOrDefault(l => l.GetProperty("rel").GetString() == "approve")
            .GetProperty("href")
            .GetString() ?? string.Empty;

        var transactionNumber = GenerateTransactionNumber();
        var transaction = new Models.Transaction
        {
            TransactionNumber = transactionNumber,
            UserId = userId,
            Amount = originalAmount,
            PaymentMethod = "PayPal",
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            ExternalTransactionId = orderId,
            Notes = $"PayPal Order: {orderId}, PayPalAmount: {paypalAmount.ToString("F2", CultureInfo.InvariantCulture)} {currencyCode}"
        };

        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync();

        return new PayPalOrderResponse
        {
            OrderId = orderId,
            ApprovalUrl = approvalUrl,
            TransactionId = transaction.Id
        };
    }

    public async Task<PaymentResult> CapturePayPalOrderAsync(string orderId, int userId)
    {
        var clientId = _configuration["PayPal:ClientId"];
        var clientSecret = _configuration["PayPal:ClientSecret"];
        var isSandbox = _configuration["PayPal:IsSandbox"]?.ToLower() == "true";

        if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(clientSecret))
        {
            throw new InvalidOperationException("PayPal credentials not configured");
        }

        var baseUrl = isSandbox 
            ? "https://api.sandbox.paypal.com" 
            : "https://api.paypal.com";

        var httpClient = new HttpClient();
        var accessToken = await GetPayPalAccessTokenAsync(httpClient, baseUrl, clientId, clientSecret);

        httpClient.DefaultRequestHeaders.Clear();
        httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {accessToken}");
        httpClient.DefaultRequestHeaders.Add("Accept", "application/json");

        var getOrderRequest = new HttpRequestMessage(HttpMethod.Get, $"{baseUrl}/v2/checkout/orders/{orderId}");
        var getOrderResponse = await httpClient.SendAsync(getOrderRequest);
        var getOrderContent = await getOrderResponse.Content.ReadAsStringAsync();

        if (getOrderResponse.IsSuccessStatusCode)
        {
            var orderData = JsonSerializer.Deserialize<JsonElement>(getOrderContent);
            var orderStatus = orderData.GetProperty("status").GetString() ?? string.Empty;
            
            if (orderStatus == "COMPLETED")
            {
                var existingTransaction = await _context.Transactions
                    .FirstOrDefaultAsync(t =>
                        t.UserId == userId &&
                        t.PaymentMethod == "PayPal" &&
                        t.Status == "pending" &&
                        t.ExternalTransactionId == orderId);

                if (existingTransaction != null)
                {
                    existingTransaction.Status = "completed";
                    existingTransaction.CompletedAt = DateTime.UtcNow;
                    try
                    {
                        var completedCaptureId = ExtractFirstPayPalCaptureId(orderData);
                        if (!string.IsNullOrWhiteSpace(completedCaptureId))
                        {
                            existingTransaction.PayPalCaptureId = completedCaptureId;
                        }
                    }
                    catch
                    {
                    }
                    await _context.SaveChangesAsync();

                    return new PaymentResult
                    {
                        Success = true,
                        TransactionId = existingTransaction.Id,
                        PaymentIntentId = orderId,
                        Message = "Payment already completed"
                    };
                }
            }
            else if (orderStatus != "APPROVED")
            {
                throw new InvalidOperationException($"PayPal order status is {orderStatus}, expected APPROVED or COMPLETED. Order data: {getOrderContent}");
            }
        }

        var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v2/checkout/orders/{orderId}/capture");
        request.Headers.Add("Authorization", $"Bearer {accessToken}");
        request.Headers.Add("Accept", "application/json");
        request.Headers.Add("Prefer", "return=representation");
        request.Content = new StringContent("{}", Encoding.UTF8, "application/json");

        var response = await httpClient.SendAsync(request);
        var responseContent = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            var txn = await _context.Transactions
                .FirstOrDefaultAsync(t =>
                    t.UserId == userId &&
                    t.PaymentMethod == "PayPal" &&
                    t.Status == "pending" &&
                    t.ExternalTransactionId == orderId);
            if (txn != null)
            {
                txn.Status = "failed";
                txn.Notes = AppendNote(txn.Notes, $"Capture failed: {response.StatusCode}", responseContent);
                await _context.SaveChangesAsync();
            }

            throw new InvalidOperationException($"PayPal capture failed (Status: {response.StatusCode}): {responseContent}");
        }

        JsonElement captureData;
        try
        {
            captureData = JsonSerializer.Deserialize<JsonElement>(responseContent);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to parse PayPal capture response: {ex.Message}. Response: {responseContent}");
        }

        var status = captureData.GetProperty("status").GetString() ?? string.Empty;

        if (status != "COMPLETED")
        {
            throw new InvalidOperationException($"PayPal order status is {status}, expected COMPLETED. Response: {responseContent}");
        }

        var transaction = await _context.Transactions
            .FirstOrDefaultAsync(t =>
                t.UserId == userId &&
                t.PaymentMethod == "PayPal" &&
                t.Status == "pending" &&
                t.ExternalTransactionId == orderId);

        if (transaction == null)
        {
            throw new InvalidOperationException($"Transaction not found for orderId: {orderId}, userId: {userId}");
        }

        var captureId = ExtractFirstPayPalCaptureId(captureData);
        if (string.IsNullOrWhiteSpace(captureId))
        {
            try
            {
                var orderDetailsResponse = await httpClient.GetAsync($"{baseUrl}/v2/checkout/orders/{orderId}");
                var orderDetailsContent = await orderDetailsResponse.Content.ReadAsStringAsync();
                if (orderDetailsResponse.IsSuccessStatusCode)
                {
                    var details = JsonSerializer.Deserialize<JsonElement>(orderDetailsContent);
                    captureId = ExtractFirstPayPalCaptureId(details);
                }
            }
            catch
            {
            }
        }

        if (string.IsNullOrWhiteSpace(captureId))
        {
            transaction.Status = "failed";
            transaction.Notes = AppendNote(transaction.Notes, "Captured but captureId missing", responseContent);
            await _context.SaveChangesAsync();
            throw new InvalidOperationException("PayPal capture succeeded but capture id was not returned; transaction marked as failed.");
        }

        transaction.Status = "completed";
        transaction.CompletedAt = DateTime.UtcNow;
        transaction.PayPalCaptureId = captureId;
        await _context.SaveChangesAsync();

        return new PaymentResult
        {
            Success = true,
            TransactionId = transaction.Id,
            PaymentIntentId = orderId,
            Message = "Payment confirmed successfully"
        };
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

    private static string AppendNote(string? existing, string label, string details)
    {
        var safeDetails = (details ?? string.Empty).Replace("\r", " ").Replace("\n", " ").Trim();
        if (safeDetails.Length > 240)
        {
            safeDetails = safeDetails.Substring(0, 240) + "...";
        }

        var entry = $"[{label}] {safeDetails}";
        if (string.IsNullOrWhiteSpace(existing))
        {
            return entry.Length <= 500 ? entry : entry.Substring(0, 500);
        }

        var combined = $"{existing} {entry}";
        return combined.Length <= 500 ? combined : combined.Substring(0, 500);
    }

    private async Task<string> GetPayPalAccessTokenAsync(HttpClient httpClient, string baseUrl, string clientId, string clientSecret)
    {
        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{clientSecret}"));

        var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/v1/oauth2/token");
        request.Headers.Add("Authorization", $"Basic {credentials}");
        request.Content = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("grant_type", "client_credentials")
        });

        var response = await httpClient.SendAsync(request);
        var responseContent = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"PayPal authentication failed: {responseContent}");
        }

        var tokenData = JsonSerializer.Deserialize<JsonElement>(responseContent);
        return tokenData.GetProperty("access_token").GetString() ?? throw new InvalidOperationException("Failed to get PayPal access token");
    }

    private string GenerateTransactionNumber()
    {
        return $"TXN-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";
    }
}
