import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../models/report_model.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  static String _transliterate(String text) {
    return text
        .replaceAll('š', 's')
        .replaceAll('Š', 'S')
        .replaceAll('č', 'c')
        .replaceAll('Č', 'C')
        .replaceAll('ć', 'c')
        .replaceAll('Ć', 'C')
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'D')
        .replaceAll('ž', 'z')
        .replaceAll('Ž', 'Z');
  }

  static Future<String?> exportTicketsToExcel(List<Ticket> tickets) async {
    try {
      var excel = Excel.createExcel();
      excel.delete('Sheet1');
      Sheet sheetObject = excel['Karte'];

      sheetObject.appendRow([
        TextCellValue('ID'),
        TextCellValue('Broj karte'),
        TextCellValue('Korisnik'),
        TextCellValue('Tip karte'),
        TextCellValue('Linija'),
        TextCellValue('Zona'),
        TextCellValue('Cijena (KM)'),
        TextCellValue('Vazna od'),
        TextCellValue('Vazna do'),
        TextCellValue('Kupljena'),
        TextCellValue('Status'),
        TextCellValue('Koristena'),
      ]);

      for (int i = 0; i < 12; i++) {
        final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      sheetObject.setColumnWidth(0, 8);
      sheetObject.setColumnWidth(1, 15);
      sheetObject.setColumnWidth(2, 25);
      sheetObject.setColumnWidth(3, 15);
      sheetObject.setColumnWidth(4, 20);
      sheetObject.setColumnWidth(5, 15);
      sheetObject.setColumnWidth(6, 12);
      sheetObject.setColumnWidth(7, 12);
      sheetObject.setColumnWidth(8, 12);
      sheetObject.setColumnWidth(9, 16);
      sheetObject.setColumnWidth(10, 12);
      sheetObject.setColumnWidth(11, 16);

      for (var ticket in tickets) {
        sheetObject.appendRow([
          IntCellValue(ticket.id),
          TextCellValue(_transliterate(ticket.ticketNumber)),
          TextCellValue(_transliterate(ticket.userEmail)),
          TextCellValue(_transliterate(ticket.ticketTypeName)),
          TextCellValue(_transliterate(ticket.routeName ?? 'Sve linije')),
          TextCellValue(_transliterate(ticket.zoneName)),
          TextCellValue(ticket.price.toStringAsFixed(2)),
          TextCellValue(_dateFormat.format(ticket.validFrom)),
          TextCellValue(_dateFormat.format(ticket.validTo)),
          TextCellValue(_dateTimeFormat.format(ticket.purchasedAt)),
          TextCellValue(_transliterate(ticket.status)),
          TextCellValue(ticket.usedAt != null ? _dateTimeFormat.format(ticket.usedAt!) : ''),
        ]);
      }

      final fileName = 'karte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(path).writeAsBytes(fileBytes);
        return path;
      }
      return null;
    } catch (e) {
      throw Exception('Greška pri izvozu u Excel: $e');
    }
  }

  static Future<String?> exportTicketsToCSV(List<Ticket> tickets) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add([
        'ID',
        'Broj karte',
        'Korisnik',
        'Tip karte',
        'Linija',
        'Zona',
        'Cijena (KM)',
        'Vazna od',
        'Vazna do',
        'Kupljena',
        'Status',
        'Koristena',
      ]);

      for (var ticket in tickets) {
        rows.add([
          ticket.id,
          _transliterate(ticket.ticketNumber),
          _transliterate(ticket.userEmail),
          _transliterate(ticket.ticketTypeName),
          _transliterate(ticket.routeName ?? 'Sve linije'),
          _transliterate(ticket.zoneName),
          ticket.price.toStringAsFixed(2),
          _dateFormat.format(ticket.validFrom),
          _dateFormat.format(ticket.validTo),
          _dateTimeFormat.format(ticket.purchasedAt),
          _transliterate(ticket.status),
          ticket.usedAt != null ? _dateTimeFormat.format(ticket.usedAt!) : '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final fileName = 'karte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      await File(path).writeAsString(csv);
      return path;
    } catch (e) {
      throw Exception('Greška pri izvozu u CSV: $e');
    }
  }

  static Future<String?> exportTicketsToPDF(List<Ticket> tickets) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  _transliterate('Pregled karata'),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1),
                  6: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildCell('ID', isHeader: true),
                      _buildCell('Broj karte', isHeader: true),
                      _buildCell('Korisnik', isHeader: true),
                      _buildCell('Tip karte', isHeader: true),
                      _buildCell('Linija', isHeader: true),
                      _buildCell('Zona', isHeader: true),
                      _buildCell('Cijena', isHeader: true),
                    ],
                  ),
                  ...tickets.take(50).map((ticket) => pw.TableRow(
                        children: [
                          _buildCell(ticket.id.toString()),
                          _buildCell(_transliterate(ticket.ticketNumber)),
                          _buildCell(_transliterate(ticket.userEmail)),
                          _buildCell(_transliterate(ticket.ticketTypeName)),
                          _buildCell(_transliterate(ticket.routeName ?? 'Sve linije')),
                          _buildCell(_transliterate(ticket.zoneName)),
                          _buildCell('${ticket.price.toStringAsFixed(2)} KM'),
                        ],
                      )),
                ],
              ),
              if (tickets.length > 50)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20),
                  child: pw.Text(
                    _transliterate('Prikazano prvih 50 od ${tickets.length} karata'),
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                ),
            ];
          },
        ),
      );

      final fileName = 'karte_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      return path;
    } catch (e) {
      throw Exception('Greška pri izvozu u PDF: $e');
    }
  }

  static Future<String?> exportReportToExcel(Report report) async {
    try {
      var excel = Excel.createExcel();
      excel.delete('Sheet1');
      Sheet sheetObject = excel['Izvještaj'];

      sheetObject.appendRow([TextCellValue('Izvestaj: ${_transliterate(report.reportTitle)}')]);
      final titleCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
      
      int currentRow = 1;
      if (report.dateFrom != null && report.dateTo != null) {
        sheetObject.appendRow([
          TextCellValue('Period: ${_dateFormat.format(report.dateFrom!)} - ${_dateFormat.format(report.dateTo!)}')
        ]);
        currentRow++;
      }
      sheetObject.appendRow([]);
      currentRow++;

      sheetObject.appendRow([TextCellValue('Sazetak')]);
      final summaryHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      summaryHeaderCell.cellStyle = CellStyle(bold: true);
      currentRow++;
      
      sheetObject.appendRow([TextCellValue('Ukupno karata'), IntCellValue(report.summary.totalTickets)]);
      currentRow++;
      sheetObject.appendRow([TextCellValue('Ukupni prihod (KM)'), TextCellValue(report.summary.totalRevenue.toStringAsFixed(2))]);
      currentRow++;
      sheetObject.appendRow([TextCellValue('Prosjecna cijena (KM)'), TextCellValue(report.summary.averagePrice.toStringAsFixed(2))]);
      currentRow++;
      sheetObject.appendRow([TextCellValue('Aktivni korisnici'), IntCellValue(report.summary.activeUsers)]);
      currentRow++;
      sheetObject.appendRow([]);
      currentRow++;

      sheetObject.appendRow([TextCellValue('Po tipu karte')]);
      final typeHeaderCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      typeHeaderCell.cellStyle = CellStyle(bold: true);
      currentRow++;
      
      sheetObject.appendRow([TextCellValue('Tip karte'), TextCellValue('Broj'), TextCellValue('Prihod (KM)')]);
      for (int i = 0; i < 3; i++) {
        final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
        cell.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      }
      currentRow++;
      
      for (var item in report.salesByTicketType) {
        sheetObject.appendRow([
          TextCellValue(_transliterate(item.ticketTypeName)),
          IntCellValue(item.count),
          TextCellValue(item.revenue.toStringAsFixed(2)),
        ]);
      }
      
      sheetObject.setColumnWidth(0, 25);
      sheetObject.setColumnWidth(1, 15);
      sheetObject.setColumnWidth(2, 15);

      final fileName = 'izvjestaj_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      final fileBytes = excel.save();
      if (fileBytes != null) {
        await File(path).writeAsBytes(fileBytes);
        return path;
      }
      return null;
    } catch (e) {
      throw Exception('Greška pri izvozu u Excel: $e');
    }
  }

  static Future<String?> exportReportToCSV(Report report) async {
    try {
      List<List<dynamic>> rows = [];

      rows.add(['Izvestaj: ${_transliterate(report.reportTitle)}']);
      if (report.dateFrom != null && report.dateTo != null) {
        rows.add(['Period: ${_dateFormat.format(report.dateFrom!)} - ${_dateFormat.format(report.dateTo!)}']);
      }
      rows.add([]);

      rows.add(['Sazetak']);
      rows.add(['Ukupno karata', report.summary.totalTickets]);
      rows.add(['Ukupni prihod (KM)', report.summary.totalRevenue.toStringAsFixed(2)]);
      rows.add(['Prosjecna cijena (KM)', report.summary.averagePrice.toStringAsFixed(2)]);
      rows.add(['Aktivni korisnici', report.summary.activeUsers]);
      rows.add([]);

      rows.add(['Po tipu karte']);
      rows.add(['Tip karte', 'Broj', 'Prihod (KM)']);
      for (var item in report.salesByTicketType) {
        rows.add([
          _transliterate(item.ticketTypeName),
          item.count,
          item.revenue.toStringAsFixed(2),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final fileName = 'izvjestaj_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      await File(path).writeAsString(csv);
      return path;
    } catch (e) {
      throw Exception('Greška pri izvozu u CSV: $e');
    }
  }

  static Future<String?> exportReportToPDF(Report report) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  _transliterate(report.reportTitle),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (report.dateFrom != null && report.dateTo != null)
                pw.Text(
                  'Period: ${_dateFormat.format(report.dateFrom!)} - ${_dateFormat.format(report.dateTo!)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 30),
              pw.Text(
                _transliterate('Sazetak'),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableRow('Ukupno karata', report.summary.totalTickets.toString()),
                  _buildTableRow('Ukupni prihod (KM)', report.summary.totalRevenue.toStringAsFixed(2)),
                  _buildTableRow('Prosjecna cijena (KM)', report.summary.averagePrice.toStringAsFixed(2)),
                  _buildTableRow('Aktivni korisnici', report.summary.activeUsers.toString()),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                _transliterate('Po tipu karte'),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildCell('Tip karte', isHeader: true),
                      _buildCell('Broj', isHeader: true),
                      _buildCell('Prihod (KM)', isHeader: true),
                    ],
                  ),
                  ...report.salesByTicketType.map((item) => pw.TableRow(
                        children: [
                          _buildCell(_transliterate(item.ticketTypeName)),
                          _buildCell(item.count.toString()),
                          _buildCell(item.revenue.toStringAsFixed(2)),
                        ],
                      )),
                ],
              ),
            ];
          },
        ),
      );

      final fileName = 'izvjestaj_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final path = await _getSavePath(fileName);
      if (path == null) return null;

      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      return path;
    } catch (e) {
      throw Exception('Greška pri izvozu u PDF: $e');
    }
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        _transliterate(text),
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        _buildCell(_transliterate(label), isHeader: true),
        _buildCell(value),
      ],
    );
  }

  static Future<String?> _getSavePath(String fileName) async {
    try {
      final extension = fileName.split('.').last;
      final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Sačuvaj fajl',
        fileName: nameWithoutExt,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      
      if (outputFile != null && !outputFile.toLowerCase().endsWith('.$extension')) {
        outputFile = '$outputFile.$extension';
      }
      
      return outputFile;
    } catch (e) {
      try {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final fullPath = '${directory.path}/$fileName';
          return fullPath;
        }
      } catch (e) {
        return fileName;
      }
    }
    return null;
  }
}
