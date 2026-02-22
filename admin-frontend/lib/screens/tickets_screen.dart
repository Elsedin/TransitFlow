import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../services/ticket_service.dart';
import '../services/ticket_type_service.dart';
import '../services/export_service.dart';
import '../models/ticket_model.dart';
import '../models/ticket_type_model.dart';
import '../widgets/metric_card_enhanced.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _ticketService = TicketService();
  final _ticketTypeService = TicketTypeService();
  TicketMetrics? _metrics;
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String? _statusFilter;
  int? _ticketTypeFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metrics = await _ticketService.getMetrics();
      final tickets = await _ticketService.getAll(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _statusFilter,
        ticketTypeId: _ticketTypeFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      setState(() {
        _metrics = metrics;
        _tickets = tickets;
        _filteredTickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tickets: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _applyFilters();
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  List<Ticket> get _paginatedTickets {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredTickets.length);
    return _filteredTickets.sublist(start, end);
  }

  int get _totalPages => (_filteredTickets.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregled svih karata',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!mounted) return;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
                  final RenderBox? button = context.findRenderObject() as RenderBox?;
                  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
                  
                  if (button == null || overlay == null) return;
                  
                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromPoints(
                      button.localToGlobal(Offset.zero, ancestor: overlay),
                      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                    ),
                    Offset.zero & overlay.size,
                  );
                  
                  final String? value = await showMenu<String>(
                    context: context,
                    position: position,
                    items: [
                      const PopupMenuItem<String>(
                        value: 'excel',
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Izvezi u Excel'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'csv',
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Izvezi u CSV'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Izvezi u PDF'),
                          ],
                        ),
                      ),
                    ],
                  );
                  
                  if (value == null || !mounted) return;
                  
                  try {
                    String? path;
                    if (value == 'excel') {
                      path = await ExportService.exportTicketsToExcel(_filteredTickets);
                    } else if (value == 'csv') {
                      path = await ExportService.exportTicketsToCSV(_filteredTickets);
                    } else if (value == 'pdf') {
                      path = await ExportService.exportTicketsToPDF(_filteredTickets);
                    }

                    if (path != null && mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Fajl je uspješno sačuvan: $path'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Greška pri izvozu: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Izvezi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_metrics != null) ...[
            Row(
              children: [
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'UKUPNO KARATA',
                    value: _formatNumber(_metrics!.totalTickets),
                    subtitle: 'U sistemu',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'AKTIVNE KARTE',
                    value: _formatNumber(_metrics!.activeTickets),
                    subtitle: 'U upotrebi',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'KORIŠTENE KARTE',
                    value: _formatNumber(_metrics!.usedTicketsThisMonth),
                    subtitle: 'U ovom mjesecu',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'ISTEKLE KARTE',
                    value: _formatNumber(_metrics!.expiredTicketsLast7Days),
                    subtitle: 'U posljednjih 7 dana',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Sve karte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraži po ID ili korisniku...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('Svi statusi'),
                    icon: const Icon(Icons.filter_list),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Svi statusi')),
                      DropdownMenuItem<String?>(value: 'aktivna', child: Text('Aktivna')),
                      DropdownMenuItem<String?>(value: 'korištena', child: Text('Korištena')),
                      DropdownMenuItem<String?>(value: 'istekla', child: Text('Istekla')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _applyFilters();
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: FutureBuilder<List<TicketType>>(
                  future: _ticketTypeService.getAll(isActive: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          items: [],
                          hint: const Text('Učitavanje...'),
                          onChanged: null,
                        ),
                      );
                    }
                    final types = snapshot.data!;
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _ticketTypeFilter,
                        hint: const Text('Svi tipovi'),
                        icon: const Icon(Icons.filter_list),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Svi tipovi')),
                          ...types.map((type) => DropdownMenuItem<int?>(
                                value: type.id,
                                child: Text(type.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _ticketTypeFilter = value;
                          });
                          _applyFilters();
                        },
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateFrom != null && _dateTo != null
                                ? '${DateFormat('dd.MM.yyyy').format(_dateFrom!)} - ${DateFormat('dd.MM.yyyy').format(_dateTo!)}'
                                : 'dd.mm.gggg - dd.mm.gggg',
                            style: TextStyle(
                              color: _dateFrom != null && _dateTo != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _buildTable(),
          ),
          if (!_isLoading && _errorMessage == null) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_paginatedTickets.isEmpty) {
      return const Center(child: Text('Nema pronađenih karata'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.8),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.3),
          7: FlexColumnWidth(2.0),
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
              _TableHeaderCell('ID karte'),
              _TableHeaderCell('Korisnik'),
              _TableHeaderCell('Tip karte'),
              _TableHeaderCell('Linija'),
              _TableHeaderCell('Datum kupovine'),
              _TableHeaderCell('Važi do'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedTickets.asMap().entries.map((entry) {
            final index = entry.key;
            final ticket = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell('#${ticket.ticketNumber}'),
                _TableCell(ticket.userEmail),
                _TableCell(ticket.ticketTypeName),
                _TableCell(ticket.routeName ?? 'Sve linije'),
                _TableCell(DateFormat('dd.MM.yyyy HH:mm').format(ticket.purchasedAt)),
                _TableCell(DateFormat('dd.MM.yyyy HH:mm').format(ticket.validTo)),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        ticket.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                      backgroundColor: ticket.status == 'Aktivna'
                          ? Colors.green
                          : ticket.status == 'Korištena'
                              ? Colors.red
                              : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          _showTicketDetails(ticket);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Detalji'),
                      ),
                      if (ticket.isActive) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            _showQRCode(ticket);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: const Text('QR kod'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Prikazano ${_paginatedTickets.length} od ${_filteredTickets.length} karata',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                child: const Text('Prethodna'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                child: const Text('Sljedeća'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalji karte #${ticket.ticketNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Korisnik:', ticket.userEmail),
              _buildDetailRow('Tip karte:', ticket.ticketTypeName),
              _buildDetailRow('Zona:', ticket.zoneName),
              _buildDetailRow('Linija:', ticket.routeName ?? 'Sve linije'),
              _buildDetailRow('Cijena:', '${ticket.price.toStringAsFixed(2)} KM'),
              _buildDetailRow('Datum kupovine:', DateFormat('dd.MM.yyyy HH:mm').format(ticket.purchasedAt)),
              _buildDetailRow('Važi od:', DateFormat('dd.MM.yyyy HH:mm').format(ticket.validFrom)),
              _buildDetailRow('Važi do:', DateFormat('dd.MM.yyyy HH:mm').format(ticket.validTo)),
              _buildDetailRow('Status:', ticket.status),
              if (ticket.isUsed && ticket.usedAt != null)
                _buildDetailRow('Korištena:', DateFormat('dd.MM.yyyy HH:mm').format(ticket.usedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showQRCode(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR kod - #${ticket.ticketNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 200,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'QR kod za kartu #${ticket.ticketNumber}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
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
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? child;

  const _TableCell(this.text, {this.color, this.child});

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }
}
