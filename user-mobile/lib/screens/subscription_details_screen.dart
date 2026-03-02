import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailsScreen({
    super.key,
    required this.subscription,
  });

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subscription = await _subscriptionService.getById(_subscription!.id);
      if (subscription != null) {
        setState(() {
          _subscription = subscription;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Pretplata nije pronađena';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazivanje pretplate'),
        content: const Text(
          'Da li ste sigurni da želite otkazati ovu pretplatu? Ova akcija je nepovratna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Otkaži'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCancelling = true;
      _errorMessage = null;
    });

    try {
      final cancelledSubscription = await _subscriptionService.cancelSubscription(_subscription!.id);
      setState(() {
        _subscription = cancelledSubscription;
        _isCancelling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pretplata je uspješno otkazana'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isCancelling = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Greška pri otkazivanju pretplate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalji pretplate'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _subscription == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalji pretplate'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
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
                onPressed: _loadSubscription,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final subscription = _subscription!;
    final isActive = subscription.isActive;
    final remainingDays = subscription.remainingDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji pretplate'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isActive ? Colors.green[700]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subscription.packageName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(subscription.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(subscription.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Preostalo: $remainingDays dana',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDetailRow('Cijena:', '${subscription.price.toStringAsFixed(2)} KM'),
                    const Divider(height: 24),
                    _buildDetailRow('Datum početka:', DateFormat('dd.MM.yyyy').format(subscription.startDate)),
                    _buildDetailRow('Datum završetka:', DateFormat('dd.MM.yyyy').format(subscription.endDate)),
                    const Divider(height: 24),
                    _buildDetailRow('Datum kupovine:', DateFormat('dd.MM.yyyy HH:mm').format(subscription.createdAt)),
                    if (subscription.transactionNumber != null)
                      _buildDetailRow('Broj transakcije:', subscription.transactionNumber!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isActive) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Informacije',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vaša aktivna pretplata omogućava neograničen broj vožnji na svim linijama javnog prevoza.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Karte koje kupujete tokom važeće pretplate su besplatne.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _cancelSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Otkaži pretplatu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      case 'expired':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktivna';
      case 'cancelled':
        return 'Otkazana';
      case 'expired':
        return 'Istekla';
      default:
        return status;
    }
  }
}
