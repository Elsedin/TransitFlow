using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;
using PdfSharp.Pdf;

namespace TransitFlow.API.Services;

public static class PdfReportBuilder
{
    public static byte[] BuildTicketSalesPdf(string title, DateTime fromUtc, DateTime toUtc, int totalTickets, decimal totalRevenue, decimal averagePrice, int activeUsers, List<(string TicketType, int Count, decimal Revenue)> byType)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Ukupno karata", totalTickets.ToString()),
            ("Ukupni prihod (KM)", FormatMoney(totalRevenue)),
            ("Prosječna cijena (KM)", FormatMoney(averagePrice)),
            ("Aktivni korisnici", activeUsers.ToString())
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Prodaja po tipu karte").Format.Font.Bold = true;

        var table = CreateTable(new[] { 7.5, 3.0, 3.5 }, new[] { "Tip karte", "Količina", "Prihod (KM)" });
        foreach (var row in byType)
        {
            AddRow(table, row.TicketType, row.Count.ToString(), FormatMoney(row.Revenue));
        }

        section.Add(table);
        return Render(doc);
    }

    public static byte[] BuildRefundRequestsPdf(string title, DateTime fromUtc, DateTime toUtc, int total, int pending, int approved, int rejected, decimal refundedTotal, List<(DateTime CreatedAtUtc, string User, string TicketNumber, decimal Amount, string Status)> rows)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Ukupno zahtjeva", total.ToString()),
            ("Pending", pending.ToString()),
            ("Odobreno", approved.ToString()),
            ("Odbijeno", rejected.ToString()),
            ("Ukupno refundirano (KM)", FormatMoney(refundedTotal))
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Lista zahtjeva (maks. 100)").Format.Font.Bold = true;

        var table = CreateTable(
            new[] { 3.5, 5.5, 3.5, 3.0, 2.5 },
            new[] { "Datum", "Korisnik", "Karta", "Iznos", "Status" }
        );

        foreach (var r in rows.Take(100))
        {
            AddRow(table,
                r.CreatedAtUtc.ToString("dd.MM.yyyy HH:mm"),
                r.User,
                r.TicketNumber,
                FormatMoney(r.Amount),
                r.Status);
        }

        section.Add(table);
        if (rows.Count > 100)
        {
            var p = section.AddParagraph($"Prikazano prvih 100 od {rows.Count} zahtjeva.");
            p.Format.Font.Size = 9;
            p.Format.Font.Italic = true;
        }

        return Render(doc);
    }

    public static byte[] BuildRevenuePdf(
        string title,
        DateTime fromUtc,
        DateTime toUtc,
        int totalTransactions,
        decimal totalRevenue,
        decimal avgAmount,
        List<(DateTime DateUtc, int Count, decimal Revenue)> rows)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Ukupno transakcija", totalTransactions.ToString()),
            ("Ukupni prihod (KM)", FormatMoney(totalRevenue)),
            ("Prosječan iznos (KM)", FormatMoney(avgAmount))
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Prihodi po danima").Format.Font.Bold = true;

        var table = CreateTable(new[] { 3.5, 3.0, 4.0 }, new[] { "Datum", "Broj", "Prihod (KM)" });
        foreach (var r in rows)
        {
            AddRow(table, r.DateUtc.ToString("dd.MM.yyyy"), r.Count.ToString(), FormatMoney(r.Revenue));
        }

        section.Add(table);
        return Render(doc);
    }

    public static byte[] BuildPopularLinesPdf(
        string title,
        DateTime fromUtc,
        DateTime toUtc,
        int totalTickets,
        decimal totalRevenue,
        List<(string LineNumber, string LineName, string Route, int Count, decimal Revenue)> rows)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Ukupno karata (Top)", totalTickets.ToString()),
            ("Ukupni prihod (Top) (KM)", FormatMoney(totalRevenue))
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Najpopularnije linije/rute (Top 50)").Format.Font.Bold = true;

        var table = CreateTable(
            new[] { 2.5, 5.0, 6.0, 2.5, 3.0 },
            new[] { "Broj", "Linija", "Ruta", "Karte", "Prihod" });

        foreach (var r in rows.Take(50))
        {
            AddRow(table, r.LineNumber, r.LineName, r.Route, r.Count.ToString(), FormatMoney(r.Revenue));
        }

        section.Add(table);
        return Render(doc);
    }

    public static byte[] BuildUserActivityPdf(
        string title,
        DateTime fromUtc,
        DateTime toUtc,
        int activeUsers,
        int totalTickets,
        decimal totalRevenue,
        List<(int UserId, string Email, int TicketCount, decimal Revenue, DateTime LastPurchaseUtc)> rows)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Aktivni korisnici (Top)", activeUsers.ToString()),
            ("Ukupno karata (Top)", totalTickets.ToString()),
            ("Ukupni prihod (Top) (KM)", FormatMoney(totalRevenue))
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Top korisnici po broju karata").Format.Font.Bold = true;

        var table = CreateTable(
            new[] { 2.5, 6.0, 2.5, 3.0, 3.5 },
            new[] { "UserId", "Email", "Karte", "Prihod", "Zadnja kupovina" });

        foreach (var r in rows.Take(50))
        {
            AddRow(table,
                r.UserId.ToString(),
                r.Email,
                r.TicketCount.ToString(),
                FormatMoney(r.Revenue),
                r.LastPurchaseUtc.ToString("dd.MM.yyyy"));
        }

        section.Add(table);
        return Render(doc);
    }

    public static byte[] BuildSubscriptionsPdf(
        string title,
        DateTime fromUtc,
        DateTime toUtc,
        int totalSubscriptions,
        decimal totalRevenue,
        List<(string PackageName, int Count, decimal Revenue)> byPackage,
        List<(int UserId, string Email, int Count, decimal TotalSpent)> topUsers)
    {
        var doc = CreateDocumentBase(title, fromUtc, toUtc);
        AddSummaryTable(doc, new (string Label, string Value)[]
        {
            ("Ukupno pretplata", totalSubscriptions.ToString()),
            ("Ukupni prihod (KM)", FormatMoney(totalRevenue))
        });

        var section = doc.LastSection;
        section.AddParagraph();
        section.AddParagraph("Pretplate po paketu").Format.Font.Bold = true;

        var table1 = CreateTable(new[] { 8.0, 3.0, 3.5 }, new[] { "Paket", "Broj", "Prihod (KM)" });
        foreach (var r in byPackage)
        {
            AddRow(table1, r.PackageName, r.Count.ToString(), FormatMoney(r.Revenue));
        }
        section.Add(table1);

        section.AddParagraph();
        section.AddParagraph("Top korisnici po potrošnji na pretplate").Format.Font.Bold = true;
        var table2 = CreateTable(new[] { 2.5, 7.0, 3.0, 3.5 }, new[] { "UserId", "Email", "Pretplate", "Potrošnja (KM)" });
        foreach (var r in topUsers.Take(50))
        {
            AddRow(table2, r.UserId.ToString(), r.Email, r.Count.ToString(), FormatMoney(r.TotalSpent));
        }
        section.Add(table2);

        return Render(doc);
    }

    private static Document CreateDocumentBase(string title, DateTime fromUtc, DateTime toUtc)
    {
        var doc = new Document();
        doc.Info.Title = title;

        var style = doc.Styles["Normal"]!;
        style.Font.Name = "Helvetica";
        style.Font.Size = 11;

        var section = doc.AddSection();
        section.PageSetup = doc.DefaultPageSetup.Clone();
        section.PageSetup.TopMargin = Unit.FromCentimeter(2.0);
        section.PageSetup.BottomMargin = Unit.FromCentimeter(2.0);
        section.PageSetup.LeftMargin = Unit.FromCentimeter(2.0);
        section.PageSetup.RightMargin = Unit.FromCentimeter(2.0);

        var h = section.AddParagraph(title);
        h.Format.Font.Size = 18;
        h.Format.Font.Bold = true;
        h.Format.SpaceAfter = Unit.FromPoint(6);

        var period = section.AddParagraph($"Period: {fromUtc:dd.MM.yyyy} - {toUtc:dd.MM.yyyy}");
        period.Format.Font.Size = 10;
        period.Format.SpaceAfter = Unit.FromPoint(10);

        return doc;
    }

    private static void AddSummaryTable(Document doc, IEnumerable<(string Label, string Value)> items)
    {
        var section = doc.LastSection!;
        section.AddParagraph("Sažetak").Format.Font.Bold = true;

        var table = new Table();
        table.Borders.Width = 0.5;
        table.AddColumn(Unit.FromCentimeter(6));
        table.AddColumn(Unit.FromCentimeter(10));

        foreach (var (label, value) in items)
        {
            var row = table.AddRow();
            row.Cells[0].AddParagraph(label).Format.Font.Bold = true;
            row.Cells[1].AddParagraph(value);
        }

        section.Add(table);
    }

    private static Table CreateTable(double[] colCm, string[] headers)
    {
        var table = new Table();
        table.Borders.Width = 0.5;
        foreach (var c in colCm)
        {
            table.AddColumn(Unit.FromCentimeter(c));
        }

        var header = table.AddRow();
        header.Shading.Color = Colors.LightGray;
        header.Format.Font.Bold = true;
        for (var i = 0; i < headers.Length; i++)
        {
            header.Cells[i].AddParagraph(headers[i]);
            header.Cells[i].Format.Alignment = ParagraphAlignment.Center;
            header.Cells[i].VerticalAlignment = VerticalAlignment.Center;
        }

        return table;
    }

    private static void AddRow(Table table, params string[] values)
    {
        var row = table.AddRow();
        for (var i = 0; i < values.Length; i++)
        {
            row.Cells[i].AddParagraph(values[i] ?? string.Empty);
        }
    }

    private static byte[] Render(Document doc)
    {
        var renderer = new PdfDocumentRenderer
        {
            Document = doc
        };
        renderer.RenderDocument();
        using var stream = new MemoryStream();
        renderer.PdfDocument.Save(stream, false);
        return stream.ToArray();
    }

    private static string FormatMoney(decimal value) => value.ToString("0.00");
}

