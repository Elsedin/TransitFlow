import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import 'ticket_details_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final _ticketService = TicketService();
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Sve';
  double _totalSpent = 0.0;
  int _totalPurchases = 0;

  final Map<String, DateTime?> _filterDates = {
    'Sve': null,
    'Ovaj mjesec': null,
    'Ovaj kvartal': null,
    'Ova godina': null,
  };

  @override
  void initState() {
    super.initState();
    _updateFilterDates();
    _loadTickets();
  }

  void _updateFilterDates() {
    final now = DateTime.now();
    _filterDates['Ovaj mjesec'] = DateTime(now.year, now.month, 1);
    _filterDates['Ovaj kvartal'] = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    _filterDates['Ova godina'] = DateTime(now.year, 1, 1);
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DateTime? dateFrom;
      if (_selectedFilter != 'Sve' && _filterDates[_selectedFilter] != null) {
        dateFrom = _filterDates[_selectedFilter];
      }

      final tickets = await _ticketService.getAll(
        dateFrom: dateFrom,
      );

      tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

      setState(() {
        _filteredTickets = tickets;
        _calculateSummary();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _calculateSummary() {
    _totalSpent = _filteredTickets.fold<double>(0.0, (sum, ticket) => sum + ticket.price);
    _totalPurchases = _filteredTickets.length;
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadTickets();
  }

  Map<String, List<Ticket>> _groupTicketsByDate(List<Ticket> tickets) {
    final grouped = <String, List<Ticket>>{};
    final dateFormat = DateFormat('dd.MM.yyyy');

    for (final ticket in tickets) {
      final dateKey = dateFormat.format(ticket.purchasedAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(ticket);
    }

    return grouped;
  }

  String _getStatusText(Ticket ticket) {
    final now = DateTime.now();
    if (ticket.isActive) {
      return 'Aktivna';
    } else if (ticket.isUsed) {
      return 'Korištena';
    } else if (ticket.validFrom.isAfter(now)) {
      return 'Neaktivna';
    } else {
      return 'Istekla';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktivna':
        return Colors.green[700]!;
      case 'Neaktivna':
        return Colors.green[600]!;
      case 'Korištena':
        return Colors.red[300]!;
      case 'Istekla':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getPaymentMethodText(Ticket ticket) {
    if (ticket.paymentMethod != null && ticket.paymentMethod!.isNotEmpty) {
      return ticket.paymentMethod!;
    }
    return 'N/A';
  }

  String _getRouteInfo(Ticket ticket) {
    if (ticket.routeName != null && ticket.routeName!.isNotEmpty) {
      final timeFormat = DateFormat('HH:mm');
      return '${ticket.routeName} • ${timeFormat.format(ticket.purchasedAt)}';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historija kupovina'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTickets,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFilterChips(),
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildTicketsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Sve', _selectedFilter == 'Sve'),
            const SizedBox(width: 8),
            _buildFilterChip('Ovaj mjesec', _selectedFilter == 'Ovaj mjesec'),
            const SizedBox(width: 8),
            _buildFilterChip('Ovaj kvartal', _selectedFilter == 'Ovaj kvartal'),
            const SizedBox(width: 8),
            _buildFilterChip('Ova godina', _selectedFilter == 'Ova godina'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(label),
      selectedColor: Colors.orange[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.orange[700],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ukupno potrošeno',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_totalSpent.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalPurchases ${_totalPurchases == 1 ? 'kupovina' : 'kupovina'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    if (_filteredTickets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nema kupovina za odabrani period',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedTickets = _groupTicketsByDate(_filteredTickets);
    final sortedDates = groupedTickets.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd.MM.yyyy').parse(a);
        final dateB = DateFormat('dd.MM.yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...sortedDates.map((date) => _buildDateSection(date, groupedTickets[date]!)),
      ],
    );
  }

  Widget _buildDateSection(String date, List<Ticket> tickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...tickets.map((ticket) => _buildTicketCard(ticket)),
      ],
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final status = _getStatusText(ticket);
    final statusColor = _getStatusColor(status);
    final paymentMethod = _getPaymentMethodText(ticket);
    final routeInfo = _getRouteInfo(ticket);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TicketDetailsScreen(ticket: ticket),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketTypeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routeInfo,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Karta: #${ticket.ticketNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Način plaćanja: $paymentMethod${ticket.isActive ? ' • Karta aktivna' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ticket.price.toStringAsFixed(2)} KM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
