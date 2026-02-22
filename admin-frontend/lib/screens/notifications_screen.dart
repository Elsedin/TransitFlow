import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../models/notification_model.dart' as models;
import '../models/user_model.dart';
import '../widgets/metric_card_enhanced.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _userService = UserService();
  models.NotificationMetrics? _metrics;
  List<models.Notification> _notifications = [];
  List<models.Notification> _filteredNotifications = [];
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  int? _userIdFilter;
  String? _typeFilter;
  bool? _isReadFilter;
  bool? _isActiveFilter;
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
      final metrics = await _notificationService.getMetrics();
      final notifications = await _notificationService.getAll(
        userId: _userIdFilter,
        type: _typeFilter,
        isRead: _isReadFilter,
        isActive: _isActiveFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      final users = await _userService.getAll();
      setState(() {
        _metrics = metrics;
        _notifications = notifications;
        _filteredNotifications = notifications;
        _users = users;
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

  List<models.Notification> get _paginatedNotifications {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredNotifications.length);
    return _filteredNotifications.sublist(start, end);
  }

  int get _totalPages => (_filteredNotifications.length / _itemsPerPage).ceil();

  Future<void> _showAddEditDialog({models.Notification? notification}) async {
    await showDialog(
      context: context,
      builder: (context) => _NotificationDialog(
        notification: notification,
        users: _users,
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteNotification(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Da li ste sigurni da želite obrisati ovu notifikaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _notificationService.delete(id);
        if (success) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifikacija je uspješno obrisana')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final success = await _notificationService.markAsRead(id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifikacija je označena kao pročitana')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upravljanje notifikacijama',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj novu notifikaciju'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    title: 'UKUPNO NOTIFIKACIJA',
                    value: _formatNumber(_metrics!.totalNotifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'NEPROČITANO',
                    value: _formatNumber(_metrics!.unreadNotifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'PROČITANO',
                    value: _formatNumber(_metrics!.readNotifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'AKTIVNO',
                    value: _formatNumber(_metrics!.activeNotifications),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'BROADCAST',
                    value: _formatNumber(_metrics!.broadcastNotifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'PO KORISNIKU',
                    value: _formatNumber(_metrics!.userSpecificNotifications),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            'Notifikacije',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pretraži notifikacije...',
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
                  child: DropdownButton<int?>(
                    value: _userIdFilter,
                    hint: const Text('Svi korisnici'),
                    icon: const Icon(Icons.filter_list),
                    style: const TextStyle(color: Colors.black87),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Svi korisnici')),
                      ..._users.map((user) => DropdownMenuItem<int?>(
                            value: user.id,
                            child: Text(user.email),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _userIdFilter = value;
                      });
                      _applyFilters();
                    },
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _typeFilter,
                    hint: const Text('Svi tipovi'),
                    icon: const Icon(Icons.filter_list),
                    style: const TextStyle(color: Colors.black87),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Svi tipovi')),
                      DropdownMenuItem<String?>(value: 'info', child: Text('Info')),
                      DropdownMenuItem<String?>(value: 'warning', child: Text('Upozorenje')),
                      DropdownMenuItem<String?>(value: 'success', child: Text('Uspjeh')),
                      DropdownMenuItem<String?>(value: 'error', child: Text('Greška')),
                      DropdownMenuItem<String?>(value: 'system', child: Text('Sistem')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _typeFilter = value;
                      });
                      _applyFilters();
                    },
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _isReadFilter,
                    hint: const Text('Status pročitanosti'),
                    icon: const Icon(Icons.filter_list),
                    style: const TextStyle(color: Colors.black87),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Svi')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Nepročitano')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Pročitano')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isReadFilter = value;
                      });
                      _applyFilters();
                    },
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _isActiveFilter,
                    hint: const Text('Aktivnost'),
                    icon: const Icon(Icons.filter_list),
                    style: const TextStyle(color: Colors.black87),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Svi')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Aktivne')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Neaktivne')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isActiveFilter = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : Column(
                      children: [
                        _buildTable(),
                        const SizedBox(height: 20),
                        _buildPagination(),
                      ],
                    ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_paginatedNotifications.isEmpty) {
      return const Center(child: Text('Nema pronađenih notifikacija'));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(2.0),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2.5),
        5: FlexColumnWidth(1.5),
        6: FlexColumnWidth(1.5),
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
            _TableHeaderCell('Naslov'),
            _TableHeaderCell('Poruka'),
            _TableHeaderCell('Tip'),
            _TableHeaderCell('Korisnik'),
            _TableHeaderCell('Status'),
            _TableHeaderCell('Datum'),
            _TableHeaderCell('Akcije'),
          ],
        ),
        ..._paginatedNotifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
            ),
            children: [
              _TableCell(
                notification.id.toString(),
                child: Center(
                  child: Text(
                    notification.id.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              _TableCell(notification.title),
              _TableCell(
                notification.message.length > 50
                    ? '${notification.message.substring(0, 50)}...'
                    : notification.message,
              ),
              _TableCell(
                notification.type.toUpperCase(),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              _TableCell(
                notification.userEmail ?? 'Svi korisnici',
                child: Tooltip(
                  message: notification.userEmail ?? 'Svi korisnici',
                  child: Text(
                    notification.userEmail ?? 'Svi korisnici',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              _TableCell(
                notification.isRead ? 'Pročitano' : 'Nepročitano',
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.isRead ? 'Pročitano' : 'Nepročitano',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              _TableCell(DateFormat('dd.MM.yyyy').format(notification.createdAt)),
              _TableCell(
                '',
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (!notification.isRead)
                      TextButton(
                        onPressed: () => _markAsRead(notification.id),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Označi'),
                      ),
                    TextButton(
                      onPressed: () => _showAddEditDialog(notification: notification),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Uredi'),
                    ),
                    TextButton(
                      onPressed: () => _deleteNotification(notification.id),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
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
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Prikazano ${_paginatedNotifications.length} od ${_filteredNotifications.length} notifikacija',
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
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _NotificationDialog extends StatefulWidget {
  final models.Notification? notification;
  final List<User> users;
  final VoidCallback onSave;

  const _NotificationDialog({
    this.notification,
    required this.users,
    required this.onSave,
  });

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notificationService = NotificationService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'info';
  int? _selectedUserId;
  bool _sendToAllUsers = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.notification != null) {
      _titleController.text = widget.notification!.title;
      _messageController.text = widget.notification!.message;
      _selectedType = widget.notification!.type;
      _selectedUserId = widget.notification!.userId;
      _sendToAllUsers = widget.notification!.userId == null;
      _isActive = widget.notification!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.notification == null) {
        await _notificationService.create(models.CreateNotificationRequest(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
          userId: _sendToAllUsers ? null : _selectedUserId,
          sendToAllUsers: _sendToAllUsers,
        ));
      } else {
        await _notificationService.update(
          widget.notification!.id,
          models.UpdateNotificationRequest(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            type: _selectedType,
            isActive: _isActive,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.notification == null
                ? 'Notifikacija je uspješno kreirana'
                : 'Notifikacija je uspješno ažurirana'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
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
      title: Text(widget.notification == null ? 'Dodaj notifikaciju' : 'Uredi notifikaciju'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Naslov *',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Poruka *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tip *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'warning', child: Text('Upozorenje')),
                  DropdownMenuItem(value: 'success', child: Text('Uspjeh')),
                  DropdownMenuItem(value: 'error', child: Text('Greška')),
                  DropdownMenuItem(value: 'system', child: Text('Sistem')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              if (widget.notification == null) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Pošalji svim korisnicima'),
                  value: _sendToAllUsers,
                  onChanged: (value) {
                    setState(() {
                      _sendToAllUsers = value ?? false;
                      if (_sendToAllUsers) {
                        _selectedUserId = null;
                      }
                    });
                  },
                ),
                if (!_sendToAllUsers) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Korisnik',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Odaberi korisnika')),
                      ...widget.users.map((user) => DropdownMenuItem<int?>(
                            value: user.id,
                            child: Text('${user.email} (${user.fullName})'),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                  ),
                ],
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Korisnik: ${widget.notification!.userEmail ?? 'Svi korisnici'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Aktivna'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
              ],
            ],
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
