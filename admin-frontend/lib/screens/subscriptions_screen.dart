import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import '../widgets/metric_card_enhanced.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _subscriptionService = SubscriptionService();
  final _userService = UserService();
  SubscriptionMetrics? _metrics;
  List<Subscription> _subscriptions = [];
  List<Subscription> _filteredSubscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String? _statusFilter;
  int? _userIdFilter;
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
      final metrics = await _subscriptionService.getMetrics();
      final subscriptions = await _subscriptionService.getAll(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _statusFilter,
        userId: _userIdFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      setState(() {
        _metrics = metrics;
        _subscriptions = subscriptions;
        _filteredSubscriptions = subscriptions;
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
    _loadData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _deleteSubscription(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši pretplatu'),
        content: const Text('Da li ste sigurni da želite obrisati ovu pretplatu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _subscriptionService.delete(id);
        if (success) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pretplata uspješno obrisana')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Neuspješno brisanje pretplate')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddEditDialog({Subscription? subscription}) async {
    await showDialog(
      context: context,
      builder: (context) => _SubscriptionDialog(
        subscription: subscription,
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  List<Subscription> get _paginatedSubscriptions {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredSubscriptions.length);
    return _filteredSubscriptions.sublist(start, end);
  }

  int get _totalPages => (_filteredSubscriptions.length / _itemsPerPage).ceil();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktivna';
      case 'expired':
        return 'Istekla';
      case 'cancelled':
        return 'Otkazana';
      default:
        return status;
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pretplate',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj pretplatu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraži pretplate...',
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
                      DropdownMenuItem<String?>(value: 'active', child: Text('Aktivna')),
                      DropdownMenuItem<String?>(value: 'expired', child: Text('Istekla')),
                      DropdownMenuItem<String?>(value: 'cancelled', child: Text('Otkazana')),
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
          if (_metrics != null) ...[
            Row(
              children: [
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'Ukupno pretplata',
                    value: _formatNumber(_metrics!.totalSubscriptions),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'Aktivne',
                    value: _formatNumber(_metrics!.activeSubscriptions),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'Istekle',
                    value: _formatNumber(_metrics!.expiredSubscriptions),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'Nove (ovaj mjesec)',
                    value: _formatNumber(_metrics!.newSubscriptionsThisMonth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'Ukupan prihod',
                    value: '${NumberFormat('#,##0.00').format(_metrics!.totalRevenue)} KM',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
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
    if (_paginatedSubscriptions.isEmpty) {
      return const Center(child: Text('Nema pronađenih pretplata'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.0),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.2),
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
              _TableHeaderCell('ID'),
              _TableHeaderCell('Korisnik'),
              _TableHeaderCell('Paket'),
              _TableHeaderCell('Cijena'),
              _TableHeaderCell('Početak'),
              _TableHeaderCell('Kraj'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedSubscriptions.asMap().entries.map((entry) {
            final index = entry.key;
            final subscription = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(subscription.id.toString()),
                _TableCell(subscription.userFullName?.isNotEmpty == true
                    ? '${subscription.userFullName}\n${subscription.userEmail}'
                    : subscription.userEmail),
                _TableCell(subscription.packageName),
                _TableCell('${NumberFormat('#,##0.00').format(subscription.price)} KM'),
                _TableCell(DateFormat('dd.MM.yyyy').format(subscription.startDate)),
                _TableCell(DateFormat('dd.MM.yyyy').format(subscription.endDate)),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        _getStatusText(subscription.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                      backgroundColor: _getStatusColor(subscription.status),
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
                        onPressed: () => _showAddEditDialog(subscription: subscription),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Uredi'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _deleteSubscription(subscription.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Obriši'),
                      ),
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
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text(
            'Stranica ${_currentPage + 1} od $_totalPages',
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
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
      width: double.infinity,
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

class _SubscriptionDialog extends StatefulWidget {
  final Subscription? subscription;
  final VoidCallback onSave;

  const _SubscriptionDialog({
    required this.subscription,
    required this.onSave,
  });

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subscriptionService = SubscriptionService();
  final _userService = UserService();
  int? _selectedUserId;
  final _packageNameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _selectedUserId = widget.subscription!.userId;
      _packageNameController.text = widget.subscription!.packageName;
      _priceController.text = widget.subscription!.price.toStringAsFixed(2);
      _selectedStatus = widget.subscription!.status;
      _startDate = widget.subscription!.startDate;
      _endDate = widget.subscription!.endDate;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAll();
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri učitavanju korisnika: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite korisnika')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite datume')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datum završetka mora biti nakon datuma početka')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        throw Exception('Cijena mora biti veća od 0');
      }

      if (widget.subscription == null) {
        await _subscriptionService.create(
          CreateSubscriptionRequest(
            userId: _selectedUserId!,
            packageName: _packageNameController.text.trim(),
            price: price,
            startDate: _startDate!,
            endDate: _endDate!,
            status: _selectedStatus,
          ),
        );
      } else {
        await _subscriptionService.update(
          widget.subscription!.id,
          UpdateSubscriptionRequest(
            packageName: _packageNameController.text.trim(),
            price: price,
            startDate: _startDate!,
            endDate: _endDate!,
            status: _selectedStatus,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.subscription == null
                ? 'Pretplata uspješno kreirana'
                : 'Pretplata uspješno ažurirana'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.subscription == null ? 'Dodaj pretplatu' : 'Uredi pretplatu'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Korisnik *',
                    border: OutlineInputBorder(),
                  ),
                  items: _users.map((user) {
                    return DropdownMenuItem<int?>(
                      value: user.id,
                      child: Text('${user.fullName} (${user.email})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite korisnika';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _packageNameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv paketa *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite naziv paketa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cijena (KM) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite cijenu';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Cijena mora biti veća od 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktivna')),
                    DropdownMenuItem(value: 'expired', child: Text('Istekla')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Otkazana')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum početka *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null
                          ? DateFormat('dd.MM.yyyy').format(_startDate!)
                          : 'Odaberite datum',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum završetka *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd.MM.yyyy').format(_endDate!)
                          : 'Odaberite datum',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
