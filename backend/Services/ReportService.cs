using Microsoft.EntityFrameworkCore;
using TransitFlow.API.Data;
using TransitFlow.API.DTOs;
using Ticket = TransitFlow.API.Models.Ticket;

namespace TransitFlow.API.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _context;

    public ReportService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ReportDto> GenerateTicketSalesReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.Tickets
            .Include(t => t.User)
            .Include(t => t.TicketType)
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo);

        if (request.TransportLineId.HasValue)
        {
            query = query.Where(t => t.Route != null && t.Route!.TransportLineId == request.TransportLineId.Value);
        }

        if (request.TicketTypeId.HasValue)
        {
            query = query.Where(t => t.TicketTypeId == request.TicketTypeId.Value);
        }

        var tickets = await query.ToListAsync();

        var totalTickets = tickets.Count;
        var totalRevenue = tickets.Sum(t => t.Price);
        var averagePrice = totalTickets > 0 ? totalRevenue / totalTickets : 0m;
        var activeUsers = tickets.Select(t => t.UserId).Distinct().Count();

        var salesByTicketType = tickets
            .GroupBy(t => new { t.TicketTypeId, TicketTypeName = t.TicketType!.Name })
            .Select(g => new ReportByTicketTypeDto
            {
                TicketTypeName = g.Key.TicketTypeName,
                Count = g.Count(),
                Revenue = g.Sum(t => t.Price)
            })
            .OrderByDescending(x => x.Revenue)
            .ToList();

        var report = new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o prodaji karata",
            DateFrom = dateFrom,
            DateTo = dateTo,
            Summary = new ReportSummaryDto
            {
                TotalTickets = totalTickets,
                TotalRevenue = totalRevenue,
                AveragePrice = averagePrice,
                ActiveUsers = activeUsers
            },
            SalesByTicketType = salesByTicketType
        };

        report.SummaryItems = new List<ReportSummaryItemDto>
        {
            new() { Label = "Ukupan broj karata", Value = totalTickets.ToString() },
            new() { Label = "Ukupan prihod (KM)", Value = totalRevenue.ToString("0.00") },
            new() { Label = "Prosječna cijena (KM)", Value = averagePrice.ToString("0.00") },
            new() { Label = "Aktivni korisnici", Value = activeUsers.ToString() },
        };

        report.Sections = new List<ReportSectionDto>
        {
            new()
            {
                Title = "Prodaja po tipovima karata",
                Columns = new List<string> { "Tip karte", "Broj", "Prihod (KM)" },
                Rows = salesByTicketType
                    .Select(x => new List<string> { x.TicketTypeName, x.Count.ToString(), x.Revenue.ToString("0.00") })
                    .ToList()
            }
        };

        return report;
    }

    public async Task<ReportDto> GenerateRevenueReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var transactions = _context.Transactions
            .Where(t => t.CreatedAt >= dateFrom && t.CreatedAt <= dateTo)
            .Where(t => t.Status != null && t.Status.ToLower() == "completed");

        var totalRevenue = await transactions.SumAsync(t => (decimal?)t.Amount) ?? 0m;
        var totalCount = await transactions.CountAsync();
        var avgAmount = totalCount > 0 ? totalRevenue / totalCount : 0m;

        var byDay = await transactions
            .GroupBy(t => t.CreatedAt.Date)
            .Select(g => new
            {
                Date = g.Key,
                Count = g.Count(),
                Revenue = g.Sum(x => x.Amount)
            })
            .OrderBy(x => x.Date)
            .ToListAsync();

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o prihodima",
            DateFrom = dateFrom,
            DateTo = dateTo,
            SummaryItems = new List<ReportSummaryItemDto>
            {
                new() { Label = "Ukupan broj transakcija", Value = totalCount.ToString() },
                new() { Label = "Ukupan prihod (KM)", Value = totalRevenue.ToString("0.00") },
                new() { Label = "Prosječan iznos (KM)", Value = avgAmount.ToString("0.00") },
            },
            Sections = new List<ReportSectionDto>
            {
                new()
                {
                    Title = "Prihod po danima",
                    Columns = new List<string> { "Datum", "Broj transakcija", "Prihod (KM)" },
                    Rows = byDay.Select(x => new List<string>
                    {
                        x.Date.ToString("dd.MM.yyyy"),
                        x.Count.ToString(),
                        x.Revenue.ToString("0.00")
                    }).ToList()
                }
            }
        };
    }

    public async Task<ReportDto> GeneratePopularLinesReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.Tickets
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo)
            .Where(t => t.Route != null && t.Route.TransportLine != null);

        if (request.TransportLineId.HasValue)
        {
            query = query.Where(t => t.Route!.TransportLineId == request.TransportLineId.Value);
        }

        var rows = await query
            .GroupBy(t => new
            {
                LineNumber = t.Route!.TransportLine!.LineNumber,
                LineName = t.Route.TransportLine.Name,
                Origin = t.Route.Origin,
                Destination = t.Route.Destination
            })
            .Select(g => new
            {
                g.Key.LineNumber,
                g.Key.LineName,
                Route = $"{g.Key.Origin} - {g.Key.Destination}",
                Count = g.Count(),
                Revenue = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.Count)
            .ThenByDescending(x => x.Revenue)
            .Take(50)
            .ToListAsync();

        var totalTickets = rows.Sum(r => r.Count);
        var totalRevenue = rows.Sum(r => r.Revenue);

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o najpopularnijim linijama i rutama",
            DateFrom = dateFrom,
            DateTo = dateTo,
            SummaryItems = new List<ReportSummaryItemDto>
            {
                new() { Label = "Ukupno karata (Top 50)", Value = totalTickets.ToString() },
                new() { Label = "Ukupan prihod (Top 50, KM)", Value = totalRevenue.ToString("0.00") },
            },
            Sections = new List<ReportSectionDto>
            {
                new()
                {
                    Title = "Top linije i rute",
                    Columns = new List<string> { "Broj linije", "Naziv", "Ruta", "Broj karata", "Prihod (KM)" },
                    Rows = rows.Select(x => new List<string>
                    {
                        x.LineNumber,
                        x.LineName,
                        x.Route,
                        x.Count.ToString(),
                        x.Revenue.ToString("0.00")
                    }).ToList()
                }
            }
        };
    }

    public async Task<ReportDto> GenerateUserActivityReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var tickets = _context.Tickets
            .Include(t => t.User)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo);

        var rows = await tickets
            .GroupBy(t => new { t.UserId, Email = t.User!.Email })
            .Select(g => new
            {
                g.Key.UserId,
                g.Key.Email,
                TicketCount = g.Count(),
                Revenue = g.Sum(x => x.Price),
                LastPurchase = g.Max(x => x.PurchasedAt)
            })
            .OrderByDescending(x => x.TicketCount)
            .ThenByDescending(x => x.Revenue)
            .Take(50)
            .ToListAsync();

        var totalActiveUsers = rows.Count;
        var totalTickets = rows.Sum(r => r.TicketCount);
        var totalRevenue = rows.Sum(r => r.Revenue);

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o aktivnosti korisnika",
            DateFrom = dateFrom,
            DateTo = dateTo,
            SummaryItems = new List<ReportSummaryItemDto>
            {
                new() { Label = "Aktivni korisnici (Top 50)", Value = totalActiveUsers.ToString() },
                new() { Label = "Ukupno karata (Top 50)", Value = totalTickets.ToString() },
                new() { Label = "Ukupan prihod (Top 50, KM)", Value = totalRevenue.ToString("0.00") },
            },
            Sections = new List<ReportSectionDto>
            {
                new()
                {
                    Title = "Top korisnici po kupovini",
                    Columns = new List<string> { "Korisnik", "Broj karata", "Prihod (KM)", "Zadnja kupovina" },
                    Rows = rows.Select(x => new List<string>
                    {
                        x.Email,
                        x.TicketCount.ToString(),
                        x.Revenue.ToString("0.00"),
                        x.LastPurchase.ToString("dd.MM.yyyy HH:mm")
                    }).ToList()
                }
            }
        };
    }

    public async Task<ReportDto> GenerateSubscriptionsReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var subs = _context.Subscriptions
            .Include(s => s.User)
            .Include(s => s.SubscriptionPackage)
            .Where(s => s.CreatedAt >= dateFrom && s.CreatedAt <= dateTo);

        var total = await subs.CountAsync();
        var totalRevenue = await subs.SumAsync(s => (decimal?)s.Price) ?? 0m;

        var byPackage = await subs
            .GroupBy(s => new { s.SubscriptionPackageId, Name = s.SubscriptionPackage!.DisplayName })
            .Select(g => new
            {
                g.Key.Name,
                Count = g.Count(),
                Revenue = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.Revenue)
            .ThenByDescending(x => x.Count)
            .ToListAsync();

        var topUsers = await subs
            .GroupBy(s => new { s.UserId, Email = s.User!.Email })
            .Select(g => new
            {
                g.Key.UserId,
                g.Key.Email,
                Count = g.Count(),
                TotalSpent = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.TotalSpent)
            .ThenByDescending(x => x.Count)
            .Take(50)
            .ToListAsync();

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o pretplatama",
            DateFrom = dateFrom,
            DateTo = dateTo,
            SummaryItems = new List<ReportSummaryItemDto>
            {
                new() { Label = "Ukupno pretplata", Value = total.ToString() },
                new() { Label = "Ukupan prihod (KM)", Value = totalRevenue.ToString("0.00") },
            },
            Sections = new List<ReportSectionDto>
            {
                new()
                {
                    Title = "Pretplate po paketima",
                    Columns = new List<string> { "Paket", "Broj", "Prihod (KM)" },
                    Rows = byPackage.Select(x => new List<string>
                    {
                        x.Name,
                        x.Count.ToString(),
                        x.Revenue.ToString("0.00")
                    }).ToList()
                },
                new()
                {
                    Title = "Top korisnici po potrošnji",
                    Columns = new List<string> { "Korisnik", "Broj pretplata", "Ukupno (KM)" },
                    Rows = topUsers.Select(x => new List<string>
                    {
                        x.Email,
                        x.Count.ToString(),
                        x.TotalSpent.ToString("0.00")
                    }).ToList()
                }
            }
        };
    }

    public async Task<ReportDto> GenerateRefundRequestsReportAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
                .ThenInclude(t => t!.Transaction)
            .Where(r => r.CreatedAt >= dateFrom && r.CreatedAt <= dateTo);

        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Take(200)
            .ToListAsync();

        var total = items.Count;
        var pending = items.Count(r => r.Status == "pending");
        var approved = items.Count(r => r.Status == "approved");
        var rejected = items.Count(r => r.Status == "rejected");

        var refundedTotal = items
            .Where(r => r.Status == "approved")
            .Sum(r => r.Ticket?.Price ?? 0m);

        return new ReportDto
        {
            ReportType = request.ReportType,
            ReportTitle = "Izvještaj o refund zahtjevima",
            DateFrom = dateFrom,
            DateTo = dateTo,
            SummaryItems = new List<ReportSummaryItemDto>
            {
                new() { Label = "Ukupno zahtjeva (prikazano)", Value = total.ToString() },
                new() { Label = "Na čekanju", Value = pending.ToString() },
                new() { Label = "Odobreno", Value = approved.ToString() },
                new() { Label = "Odbijeno", Value = rejected.ToString() },
                new() { Label = "Refundirano ukupno (KM)", Value = refundedTotal.ToString("0.00") },
            },
            Sections = new List<ReportSectionDto>
            {
                new()
                {
                    Title = "Zahtjevi",
                    Columns = new List<string> { "Kreirano", "Korisnik", "Karta", "Iznos (KM)", "Status" },
                    Rows = items.Select(r => new List<string>
                    {
                        r.CreatedAt.ToString("dd.MM.yyyy HH:mm"),
                        r.User?.Email ?? r.UserId.ToString(),
                        r.Ticket?.TicketNumber ?? r.TicketId.ToString(),
                        (r.Ticket?.Price ?? 0m).ToString("0.00"),
                        r.Status
                    }).ToList()
                }
            }
        };
    }

    public async Task<byte[]> GenerateTicketSalesPdfAsync(ReportRequestDto request)
    {
        var report = await GenerateTicketSalesReportAsync(request);
        var from = report.DateFrom!.Value;
        var to = report.DateTo!.Value;

        var byType = report.SalesByTicketType
            .Select(x => (x.TicketTypeName, x.Count, x.Revenue))
            .ToList();

        return PdfReportBuilder.BuildTicketSalesPdf(
            report.ReportTitle,
            from,
            to,
            report.Summary.TotalTickets,
            report.Summary.TotalRevenue,
            report.Summary.AveragePrice,
            report.Summary.ActiveUsers,
            byType);
    }

    public async Task<byte[]> GenerateRefundRequestsPdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.RefundRequests
            .Include(r => r.User)
            .Include(r => r.Ticket)
                .ThenInclude(t => t!.Transaction)
            .Where(r => r.CreatedAt >= dateFrom && r.CreatedAt <= dateTo);

        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var total = items.Count;
        var pending = items.Count(r => r.Status == "pending");
        var approved = items.Count(r => r.Status == "approved");
        var rejected = items.Count(r => r.Status == "rejected");

        var refundedTotal = items
            .Where(r => r.Status == "approved")
            .Sum(r => r.Ticket?.Price ?? 0m);

        var rows = items.Select(r =>
        {
            var user = r.User?.Email ?? r.UserId.ToString();
            var ticketNo = r.Ticket?.TicketNumber ?? r.TicketId.ToString();
            var amount = r.Ticket?.Price ?? 0m;
            return (r.CreatedAt, user, ticketNo, amount, r.Status);
        }).ToList();

        return PdfReportBuilder.BuildRefundRequestsPdf(
            "Izvještaj o refund zahtjevima",
            dateFrom,
            dateTo,
            total,
            pending,
            approved,
            rejected,
            refundedTotal,
            rows);
    }

    public async Task<byte[]> GenerateRevenuePdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var transactions = _context.Transactions
            .Where(t => t.CreatedAt >= dateFrom && t.CreatedAt <= dateTo)
            .Where(t => t.Status != null && t.Status.ToLower() == "completed");

        var totalRevenue = await transactions.SumAsync(t => (decimal?)t.Amount) ?? 0m;
        var totalCount = await transactions.CountAsync();
        var avgAmount = totalCount > 0 ? totalRevenue / totalCount : 0m;

        var byDay = await transactions
            .GroupBy(t => t.CreatedAt.Date)
            .Select(g => new
            {
                Date = g.Key,
                Count = g.Count(),
                Revenue = g.Sum(x => x.Amount)
            })
            .OrderBy(x => x.Date)
            .ToListAsync();

        var rows = byDay.Select(x => (x.Date, x.Count, x.Revenue)).ToList();

        return PdfReportBuilder.BuildRevenuePdf(
            "Izvještaj o prihodima",
            dateFrom,
            dateTo,
            totalCount,
            totalRevenue,
            avgAmount,
            rows);
    }

    public async Task<byte[]> GeneratePopularLinesPdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var query = _context.Tickets
            .Include(t => t.Route)
                .ThenInclude(r => r!.TransportLine)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo)
            .Where(t => t.Route != null && t.Route.TransportLine != null);

        if (request.TransportLineId.HasValue)
        {
            query = query.Where(t => t.Route!.TransportLineId == request.TransportLineId.Value);
        }

        var rows = await query
            .GroupBy(t => new
            {
                LineNumber = t.Route!.TransportLine!.LineNumber,
                LineName = t.Route.TransportLine.Name,
                Origin = t.Route.Origin,
                Destination = t.Route.Destination
            })
            .Select(g => new
            {
                g.Key.LineNumber,
                g.Key.LineName,
                Route = $"{g.Key.Origin} - {g.Key.Destination}",
                Count = g.Count(),
                Revenue = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.Count)
            .ThenByDescending(x => x.Revenue)
            .Take(50)
            .ToListAsync();

        var totalTickets = rows.Sum(r => r.Count);
        var totalRevenue = rows.Sum(r => r.Revenue);

        return PdfReportBuilder.BuildPopularLinesPdf(
            "Izvještaj o najpopularnijim linijama i rutama",
            dateFrom,
            dateTo,
            totalTickets,
            totalRevenue,
            rows.Select(r => (r.LineNumber, r.LineName, r.Route, r.Count, r.Revenue)).ToList());
    }

    public async Task<byte[]> GenerateUserActivityPdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var tickets = _context.Tickets
            .Include(t => t.User)
            .Where(t => t.PurchasedAt >= dateFrom && t.PurchasedAt <= dateTo);

        var rows = await tickets
            .GroupBy(t => new { t.UserId, Email = t.User!.Email })
            .Select(g => new
            {
                g.Key.UserId,
                g.Key.Email,
                TicketCount = g.Count(),
                Revenue = g.Sum(x => x.Price),
                LastPurchase = g.Max(x => x.PurchasedAt)
            })
            .OrderByDescending(x => x.TicketCount)
            .ThenByDescending(x => x.Revenue)
            .Take(50)
            .ToListAsync();

        var totalActiveUsers = rows.Count;
        var totalTickets = rows.Sum(r => r.TicketCount);
        var totalRevenue = rows.Sum(r => r.Revenue);

        return PdfReportBuilder.BuildUserActivityPdf(
            "Izvještaj o aktivnosti korisnika",
            dateFrom,
            dateTo,
            totalActiveUsers,
            totalTickets,
            totalRevenue,
            rows.Select(r => (r.UserId, r.Email, r.TicketCount, r.Revenue, r.LastPurchase)).ToList());
    }

    public async Task<byte[]> GenerateSubscriptionsPdfAsync(ReportRequestDto request)
    {
        var (dateFrom, dateTo) = ResolvePeriod(request);

        var subs = _context.Subscriptions
            .Include(s => s.User)
            .Include(s => s.SubscriptionPackage)
            .Where(s => s.CreatedAt >= dateFrom && s.CreatedAt <= dateTo);

        var total = await subs.CountAsync();
        var totalRevenue = await subs.SumAsync(s => (decimal?)s.Price) ?? 0m;

        var byPackage = await subs
            .GroupBy(s => new { s.SubscriptionPackageId, Name = s.SubscriptionPackage!.DisplayName })
            .Select(g => new
            {
                g.Key.Name,
                Count = g.Count(),
                Revenue = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.Revenue)
            .ThenByDescending(x => x.Count)
            .ToListAsync();

        var topUsers = await subs
            .GroupBy(s => new { s.UserId, Email = s.User!.Email })
            .Select(g => new
            {
                g.Key.UserId,
                g.Key.Email,
                Count = g.Count(),
                TotalSpent = g.Sum(x => x.Price)
            })
            .OrderByDescending(x => x.TotalSpent)
            .ThenByDescending(x => x.Count)
            .Take(50)
            .ToListAsync();

        return PdfReportBuilder.BuildSubscriptionsPdf(
            "Izvještaj o pretplatama",
            dateFrom,
            dateTo,
            total,
            totalRevenue,
            byPackage.Select(x => (x.Name, x.Count, x.Revenue)).ToList(),
            topUsers.Select(x => (x.UserId, x.Email, x.Count, x.TotalSpent)).ToList());
    }

    private static (DateTime dateFrom, DateTime dateTo) ResolvePeriod(ReportRequestDto request)
    {
        var dateFrom = request.DateFrom;
        var dateTo = request.DateTo;

        if (!string.IsNullOrWhiteSpace(request.Period))
        {
            var now = DateTime.UtcNow;
            dateFrom = request.Period.ToLower() switch
            {
                "danas" => now.Date,
                "ovaj tjedan" => now.Date.AddDays(-(int)now.DayOfWeek),
                "ovaj mjesec" => new DateTime(now.Year, now.Month, 1),
                "ovaj godina" => new DateTime(now.Year, 1, 1),
                _ => dateFrom
            };
            dateTo = request.Period.ToLower() switch
            {
                "danas" => now.Date.AddDays(1).AddTicks(-1),
                "ovaj tjedan" => now.Date.AddDays(7 - (int)now.DayOfWeek).AddTicks(-1),
                "ovaj mjesec" => new DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month), 23, 59, 59),
                "ovaj godina" => new DateTime(now.Year, 12, 31, 23, 59, 59),
                _ => dateTo
            };
        }

        var from = dateFrom ?? DateTime.UtcNow.AddDays(-30).Date;
        var to = dateTo ?? DateTime.UtcNow.Date.AddDays(1).AddTicks(-1);
        return (from, to);
    }
}
