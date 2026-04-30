import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../widgets/metric_card_enhanced.dart';
import '../widgets/pagination_bar.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _transactionService = TransactionService();
  TransactionMetrics? _metrics;
  List<Transaction> _pagedTransactions = [];
  int _totalCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String? _statusFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _currentPage = 0;
  int _itemsPerPage = 5;

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
      final metrics = await _transactionService.getMetrics();
      final pageResult = await _transactionService.getPaged(
        page: _currentPage + 1,
        pageSize: _itemsPerPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _statusFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      
      setState(() {
        _metrics = metrics;
        _pagedTransactions = pageResult.items;
        _totalCount = pageResult.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
    });
    _loadData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

  List<Transaction> get _paginatedTransactions {
    return _pagedTransactions;
  }

  int get _totalPages => (_totalCount / _itemsPerPage).ceil();

  Widget _buildPagination() {
    return PaginationBar(
      page: _currentPage + 1,
      pageSize: _itemsPerPage,
      totalCount: _totalCount,
      totalPages: _totalPages,
      onPrev: _currentPage > 0
          ? () {
              setState(() => _currentPage--);
              _loadData();
            }
          : null,
      onNext: _currentPage < _totalPages - 1
          ? () {
              setState(() => _currentPage++);
              _loadData();
            }
          : null,
      onPageSizeChanged: (v) {
        setState(() {
          _currentPage = 0;
          _itemsPerPage = v;
        });
        _loadData();
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Završena';
      case 'pending':
        return 'Na čekanju';
      case 'failed':
        return 'Neuspješna';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transakcije',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (_metrics != null) _buildMetrics(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraži po broju transakcije, korisniku...',
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
                      DropdownMenuItem<String?>(value: 'completed', child: Text('Završena')),
                      DropdownMenuItem<String?>(value: 'pending', child: Text('Na čekanju')),
                      DropdownMenuItem<String?>(value: 'failed', child: Text('Neuspješna')),
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

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: MetricCardEnhanced(
            title: 'Ukupno transakcija',
            value: _metrics!.totalTransactions.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCardEnhanced(
            title: 'Završene',
            value: _metrics!.completedTransactions.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCardEnhanced(
            title: 'Na čekanju',
            value: _metrics!.pendingTransactions.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCardEnhanced(
            title: 'Ukupan prihod',
            value: '${NumberFormat('#,##0.00').format(_metrics!.totalRevenue)} KM',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetricCardEnhanced(
            title: 'Prihod ovaj mjesec',
            value: '${NumberFormat('#,##0.00').format(_metrics!.revenueThisMonth)} KM',
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_paginatedTransactions.isEmpty) {
      return const Center(child: Text('Nema pronađenih transakcija'));
    }

    final headerRow = TableRow(
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      children: const [
        _TableHeaderCell('Broj transakcije'),
        _TableHeaderCell('Korisnik'),
        _TableHeaderCell('Iznos'),
        _TableHeaderCell('Način plaćanja'),
        _TableHeaderCell('Datum'),
        _TableHeaderCell('Status'),
        _TableHeaderCell('Karte'),
      ],
    );

    final bodyRows = _paginatedTransactions.asMap().entries.map((entry) {
      final index = entry.key;
      final transaction = entry.value;
      return TableRow(
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        ),
        children: [
          _TableCell('#${transaction.transactionNumber}'),
          _TableCell(transaction.userFullName?.isNotEmpty == true
              ? '${transaction.userFullName}\n${transaction.userEmail}'
              : transaction.userEmail),
          _TableCell('${NumberFormat('#,##0.00').format(transaction.amount)} KM'),
          _TableCell(transaction.paymentMethod),
          _TableCell(DateFormat('dd.MM.yyyy HH:mm').format(transaction.createdAt)),
          _TableCell(
            '',
            child: Center(
              child: Chip(
                label: Text(
                  _getStatusText(transaction.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.visible,
                ),
                backgroundColor: _getStatusColor(transaction.status),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          _TableCell(transaction.ticketCount.toString()),
        ],
      );
    }).toList();

    return Column(
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.8),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.3),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(1.0),
          },
          children: [headerRow],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.8),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.3),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.0),
        },
              children: bodyRows,
            ),
          ),
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
  final Widget? child;

  const _TableCell(this.text, {this.child});

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
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
