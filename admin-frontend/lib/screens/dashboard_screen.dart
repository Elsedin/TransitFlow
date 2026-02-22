import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import '../widgets/metric_card_enhanced.dart';
import '../widgets/ticket_sales_chart.dart';
import '../widgets/ticket_type_chart.dart';
import '../widgets/popular_lines_table.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();
  final _authService = AuthService();
  DashboardMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metrics = await _dashboardService.getMetrics();
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Neuspješno učitavanje metrika';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###').format(amount)} KM';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMetrics,
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      )
                    : _metrics == null
                        ? const Center(child: Text('Nema dostupnih podataka'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: MetricCardEnhanced(
                                        title: 'UKUPNO KORISNIKA',
                                        value: _formatNumber(_metrics!.totalUsers),
                                        changeText: '+${_metrics!.totalUsersChange.toStringAsFixed(1)}% od prošlog mjeseca',
                                        isPositiveChange: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: MetricCardEnhanced(
                                        title: 'PRODANE KARTE (DANAS)',
                                        value: _formatNumber(_metrics!.soldTicketsToday),
                                        changeText: '+${_metrics!.soldTicketsChange.toStringAsFixed(1)}% od juče',
                                        isPositiveChange: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: MetricCardEnhanced(
                                        title: 'MJESEČNI PRIHODI',
                                        value: _formatCurrency(_metrics!.monthlyRevenue),
                                        changeText: '+${_metrics!.monthlyRevenueChange.toStringAsFixed(1)}% od prošlog mjeseca',
                                        isPositiveChange: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: MetricCardEnhanced(
                                        title: 'AKTIVNE LINIJE',
                                        value: _metrics!.activeLines.toString(),
                                        subtitle: 'Sve aktivne',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TicketSalesChart(data: _metrics!.ticketSalesData),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: TicketTypeChart(data: _metrics!.ticketTypeDistribution),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                PopularLinesTable(lines: _metrics!.popularLines),
                              ],
                            ),
                          ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
}
