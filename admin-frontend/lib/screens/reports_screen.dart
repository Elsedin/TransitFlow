import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../services/transport_line_service.dart';
import '../services/ticket_type_service.dart';
import '../services/export_service.dart';
import '../models/report_model.dart';
import '../models/transport_line_model.dart';
import '../models/ticket_type_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();
  final _transportLineService = TransportLineService();
  final _ticketTypeService = TicketTypeService();
  
  String _reportType = 'ticket_sales';
  String? _period;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _selectedTransportLineId;
  int? _selectedTicketTypeId;
  
  Report? _currentReport;
  bool _isGenerating = false;
  String? _errorMessage;
  
  List<TransportLine> _transportLines = [];
  List<TicketType> _ticketTypes = [];

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final lines = await _transportLineService.getAll(isActive: true);
      final types = await _ticketTypeService.getAll(isActive: true);
      setState(() {
        _transportLines = lines;
        _ticketTypes = types;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri učitavanju podataka: $e')),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final request = ReportRequest(
        reportType: _reportType,
        period: _period,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        transportLineId: _selectedTransportLineId,
        ticketTypeId: _selectedTicketTypeId,
      );

      final report = await _reportService.generateReport(request);
      
      setState(() {
        _currentReport = report;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _selectDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked;
      });
    }
  }

  Future<void> _selectDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? (_dateFrom ?? DateTime.now()),
      firstDate: _dateFrom ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateTo = picked;
      });
    }
  }

  void _handlePeriodChange(String? value) {
    setState(() {
      _period = value;
      if (value != null) {
        _dateFrom = null;
        _dateTo = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildParametersPanel(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _buildPreviewPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersPanel() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parametri izvještaja',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _reportType,
              decoration: InputDecoration(
                labelText: 'Tip izvještaja',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ticket_sales', child: Text('Prodaja karata')),
              ],
              onChanged: (value) {
                setState(() {
                  _reportType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _period,
              decoration: InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Prilagođeno')),
                DropdownMenuItem<String?>(value: 'danas', child: Text('Danas')),
                DropdownMenuItem<String?>(value: 'ovaj tjedan', child: Text('Ovaj tjedan')),
                DropdownMenuItem<String?>(value: 'ovaj mjesec', child: Text('Ovaj mjesec')),
                DropdownMenuItem<String?>(value: 'ovaj godina', child: Text('Ovaj godina')),
              ],
              onChanged: _handlePeriodChange,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDateFrom,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Od datuma',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateFrom != null
                      ? DateFormat('dd.MM.yyyy').format(_dateFrom!)
                      : 'dd.mm.gggg',
                  style: TextStyle(
                    color: _dateFrom != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDateTo,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Do datuma',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateTo != null
                      ? DateFormat('dd.MM.yyyy').format(_dateTo!)
                      : 'dd.mm.gggg',
                  style: TextStyle(
                    color: _dateTo != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _selectedTransportLineId,
              decoration: InputDecoration(
                labelText: 'Linija (opciono)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sve linije')),
                ..._transportLines.map((line) => DropdownMenuItem<int?>(
                      value: line.id,
                      child: Text('${line.lineNumber} - ${line.name}'),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTransportLineId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _selectedTicketTypeId,
              decoration: InputDecoration(
                labelText: 'Tip karte (opciono)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Svi tipovi')),
                ..._ticketTypes.map((type) => DropdownMenuItem<int?>(
                      value: type.id,
                      child: Text(type.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTicketTypeId = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Generiši izvještaj'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pregled izvještaja',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentReport != null)
                  Row(
                    children: [
                      _buildExportButton('PDF', Icons.picture_as_pdf),
                      const SizedBox(width: 8),
                      _buildExportButton('Excel', Icons.table_chart),
                      const SizedBox(width: 8),
                      _buildExportButton('CSV', Icons.file_download),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isGenerating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_currentReport == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Odaberite parametre i generišite izvještaj',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: _buildReportContent(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: _currentReport == null
          ? null
          : () async {
              try {
                String? path;
                if (label == 'PDF') {
                  path = await ExportService.exportReportToPDF(_currentReport!);
                } else if (label == 'Excel') {
                  path = await ExportService.exportReportToExcel(_currentReport!);
                } else if (label == 'CSV') {
                  path = await ExportService.exportReportToCSV(_currentReport!);
                }

                if (path != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fajl je uspješno sačuvan: $path'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Greška pri izvozu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_currentReport == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TransitFlow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentReport!.reportTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_currentReport!.dateFrom != null && _currentReport!.dateTo != null)
          Text(
            'Period: ${DateFormat('dd.MM.yyyy').format(_currentReport!.dateFrom!)} - ${DateFormat('dd.MM.yyyy').format(_currentReport!.dateTo!)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        const SizedBox(height: 32),
        const Text(
          'Sažetak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Ukupan broj karata',
                _currentReport!.summary.totalTickets.toString(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Ukupan prihod',
                '${NumberFormat('#,##0.00').format(_currentReport!.summary.totalRevenue)} KM',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Prosječna cijena',
                '${NumberFormat('#,##0.00').format(_currentReport!.summary.averagePrice)} KM',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Aktivna Korisnici',
                _currentReport!.summary.activeUsers.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Prodaja po tipovima karata',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSalesTable(),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable() {
    if (_currentReport!.salesByTicketType.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Nema podataka'),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.0),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.0),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          children: const [
            _TableHeaderCell('Tip karte'),
            _TableHeaderCell('Broj'),
            _TableHeaderCell('Prihod'),
          ],
        ),
        ..._currentReport!.salesByTicketType.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
            ),
            children: [
              _TableCell(item.ticketTypeName),
              _TableCell(NumberFormat('#,###').format(item.count)),
              _TableCell('${NumberFormat('#,##0.00').format(item.revenue)} KM'),
            ],
          );
        }),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
