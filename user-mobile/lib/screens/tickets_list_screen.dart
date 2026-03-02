import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import 'ticket_details_screen.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen>
    with SingleTickerProviderStateMixin {
  final _ticketService = TicketService();
  late TabController _tabController;
  List<Ticket> _activeTickets = [];
  List<Ticket> _usedTickets = [];
  List<Ticket> _expiredTickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allTickets = await _ticketService.getAll();
      final now = DateTime.now();

      setState(() {
        _activeTickets = allTickets
            .where((t) => !t.isUsed && t.validTo.isAfter(now))
            .toList()
          ..sort((a, b) => b.validTo.compareTo(a.validTo));

        _usedTickets = allTickets
            .where((t) => t.isUsed)
            .toList()
          ..sort((a, b) {
            if (a.usedAt == null && b.usedAt == null) return 0;
            if (a.usedAt == null) return 1;
            if (b.usedAt == null) return -1;
            return b.usedAt!.compareTo(a.usedAt!);
          });

        _expiredTickets = allTickets
            .where((t) => !t.isUsed && t.validTo.isBefore(now))
            .toList()
          ..sort((a, b) => b.validTo.compareTo(a.validTo));

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karte'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Aktivne'),
            Tab(text: 'Korištene'),
            Tab(text: 'Istekle'),
          ],
        ),
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketsList(_activeTickets, 'Aktivne'),
                      _buildTicketsList(_usedTickets, 'Korištene'),
                      _buildTicketsList(_expiredTickets, 'Istekle'),
                    ],
                  ),
                ),
    );
  }

  String _getEmptyStateMessage(String title) {
    switch (title) {
      case 'Aktivne':
        return 'Nema aktivnih karata';
      case 'Korištene':
        return 'Nema korištenih karata';
      case 'Istekle':
        return 'Nema isteklih karata';
      default:
        return 'Nema karata';
    }
  }

  Widget _buildTicketsList(List<Ticket> tickets, String title) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(title),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
    final now = DateTime.now();
    final isActive = !ticket.isUsed && ticket.validTo.isAfter(now);

    String dateText;
    if (ticket.ticketTypeName.toLowerCase().contains('mjesečn') ||
        ticket.ticketTypeName.toLowerCase().contains('godišnj')) {
      dateText =
          '${dateFormat.format(ticket.validFrom)} - ${dateFormat.format(ticket.validTo)}';
    } else {
      dateText = dateFormat.format(ticket.validFrom);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TicketDetailsScreen(ticket: ticket),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.orange[700]
                      : ticket.isUsed
                          ? Colors.grey[400]
                          : Colors.red[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.confirmation_number,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
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
                      dateText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (ticket.routeName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        ticket.routeName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ticket.price.toStringAsFixed(2)} KM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green[100]
                          : ticket.isUsed
                              ? Colors.grey[200]
                              : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.green[800]
                            : ticket.isUsed
                                ? Colors.grey[800]
                                : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
