import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../services/ticket_service.dart';
import '../services/transport_line_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../models/ticket_model.dart';
import '../models/subscription_model.dart';
import '../models/transport_line_model.dart' as models;
import 'ticket_success_screen.dart';
import 'paypal_payment_screen.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final int? lineId;
  final int? routeId;

  const TicketPurchaseScreen({
    super.key,
    this.lineId,
    this.routeId,
  });

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  final _ticketService = TicketService();
  final _transportLineService = TransportLineService();
  final _paymentService = PaymentService();
  final _subscriptionService = SubscriptionService();

  models.TransportLine? _selectedLine;
  models.Route? _selectedRoute;
  TicketType? _selectedTicketType;
  TicketPrice? _selectedTicketPrice;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _paymentMethod;
  List<TicketType> _ticketTypes = [];
  List<TicketPrice> _ticketPrices = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;
  Subscription? _activeSubscription;
  int? _activeSubscriptionMaxZoneId;
  List<SubscriptionPackage> _subscriptionPackages = [];

  bool get _coversSelection {
    final zoneId = _selectedTicketPrice?.zoneId;
    final maxZone = _activeSubscriptionMaxZoneId;
    if (zoneId == null || maxZone == null) return false;
    return maxZone >= zoneId;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _activeSubscription = await _subscriptionService.getActiveSubscription();
      if (_activeSubscription != null) {
        try {
          _subscriptionPackages = await _subscriptionService.fetchAvailablePackages();
          final match = _subscriptionPackages
              .where((p) => p.displayName == _activeSubscription!.packageName)
              .toList();
          if (match.isNotEmpty) {
            _activeSubscriptionMaxZoneId = match.first.maxZoneId;
          } else {
            _activeSubscriptionMaxZoneId = null;
          }
        } catch (_) {
          _activeSubscriptionMaxZoneId = null;
        }
      } else {
        _activeSubscriptionMaxZoneId = null;
      }

      if (widget.lineId != null) {
        final line = await _transportLineService.getById(widget.lineId!);
        if (line != null) {
          final route = await _transportLineService.getRouteByLineId(line.id);
          setState(() {
            _selectedLine = line;
            _selectedRoute = route;
          });
        }
      } else if (widget.routeId != null) {
        final route = await _transportLineService.getRouteById(widget.routeId!);
        if (route != null) {
          setState(() {
            _selectedRoute = route;
          });
        }
      }

      final ticketTypes = await _ticketService.getTicketTypes(isActive: true);
      setState(() {
        _ticketTypes = ticketTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTicketPrices() async {
    if (_selectedTicketType == null || _selectedRoute == null) return;

    try {
      final prices = await _ticketService.getTicketPrices(
        ticketTypeId: _selectedTicketType!.id,
        isActive: true,
      );
      setState(() {
        _ticketPrices = prices;
        if (prices.isNotEmpty) {
          _selectedTicketPrice = prices.first;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Greška pri učitavanju cijena karata';
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja'];
    return days[date.weekday - 1];
  }

  double _getTotalPrice() {
    return _selectedTicketPrice?.price ?? 0.0;
  }

  Future<void> _purchaseTicket() async {
    if (_selectedTicketType == null || _selectedRoute == null || _selectedTicketPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite sve potrebne podatke')),
      );
      return;
    }

    if (_coversSelection) {
      await _createTicketWithoutPayment();
      return;
    }

    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite način plaćanja')),
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      if (_paymentMethod == 'card') {
        await _processStripePayment();
      } else if (_paymentMethod == 'paypal') {
        await _processPayPalPayment();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isPurchasing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Greška pri kupovini karte')),
        );
      }
    }
  }

  Future<void> _createTicketWithoutPayment() async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final validTo = selectedDateTime.add(Duration(days: _selectedTicketType!.validityDays));

      final ticket = await _ticketService.purchaseTicket(
        ticketTypeId: _selectedTicketType!.id,
        routeId: _selectedRoute!.id,
        zoneId: _selectedTicketPrice!.zoneId,
        validFrom: selectedDateTime.toUtc(),
        validTo: validTo.toUtc(),
        transactionId: null,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TicketSuccessScreen(ticket: ticket),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isPurchasing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Greška pri kreiranju karte')),
        );
      }
    }
  }

  Future<void> _processStripePayment() async {
    try {
      final totalPrice = _getTotalPrice();

      final paymentIntent = await _paymentService.createStripePaymentIntent(totalPrice);

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'TransitFlow',
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      final authService = AuthService();
      final isAuth = await authService.isAuthenticated();
      if (!isAuth) {
        throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
      }

      final result = await _paymentService.confirmStripePayment(paymentIntent.paymentIntentId);

      if (result.success) {
        await _createTicketAfterPayment(result.transactionId);
      } else {
        throw Exception(result.message ?? 'Plaćanje nije uspješno');
      }
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        setState(() {
          _isPurchasing = false;
        });
      } else {
        throw Exception('Stripe greška: ${e.error.message}');
      }
    } catch (e) {
      throw Exception('Greška pri plaćanju: $e');
    }
  }

  Future<void> _processPayPalPayment() async {
    try {
      final totalPrice = _getTotalPrice();

      final paypalOrder = await _paymentService.createPayPalOrder(totalPrice);

      if (!mounted) return;
      
      setState(() {
        _errorMessage = null;
      });
      
      final returnedOrderId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => PayPalPaymentScreen(
            approvalUrl: paypalOrder.approvalUrl,
            orderId: paypalOrder.orderId,
            onPaymentComplete: (String orderId) {
            },
            onPaymentCancel: () {
            },
          ),
        ),
      );

      if (returnedOrderId != null && returnedOrderId.isNotEmpty) {
        final authService = AuthService();
        final isAuth = await authService.isAuthenticated();
        if (!isAuth) {
          throw Exception('Sesija je istekla. Molimo prijavite se ponovo.');
        }

        final paymentResult = await _paymentService.capturePayPalOrder(paypalOrder.orderId);

        if (paymentResult.success) {
          await _createTicketAfterPayment(paymentResult.transactionId);
        } else {
          throw Exception(paymentResult.message ?? 'Plaćanje nije uspješno');
        }
      } else {
        setState(() {
          _isPurchasing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPurchasing = false;
      });
      throw Exception('Greška pri PayPal plaćanju: $e');
    }
  }

  Future<void> _createTicketAfterPayment(int transactionId) async {
    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final validTo = selectedDateTime.add(Duration(days: _selectedTicketType!.validityDays));

      final ticket = await _ticketService.purchaseTicket(
        ticketTypeId: _selectedTicketType!.id,
        routeId: _selectedRoute!.id,
        zoneId: _selectedTicketPrice!.zoneId,
        validFrom: selectedDateTime.toUtc(),
        validTo: validTo.toUtc(),
        transactionId: transactionId,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TicketSuccessScreen(ticket: ticket),
          ),
        );
      }
    } catch (e) {
      throw Exception('Greška pri kreiranju karte: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kupovina karte'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kupovina karte'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedLine != null && _selectedRoute != null)
              _buildLineInfoCard(),
            const SizedBox(height: 16),
            _buildDateAndTimeSection(),
            const SizedBox(height: 16),
            _buildTicketTypeSection(),
            if (_selectedTicketType != null) ...[
              const SizedBox(height: 16),
              if (_ticketPrices.isNotEmpty)
                _buildTicketPriceSection()
              else
                _buildNoTicketPriceMessage(),
            ],
            if (!_coversSelection) ...[
              const SizedBox(height: 16),
              _buildPaymentMethodSection(),
            ] else ...[
              const SizedBox(height: 16),
              _buildSubscriptionInfoCard(),
            ],
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildPurchaseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLineInfoCard() {
    if (_selectedLine == null || _selectedRoute == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLine!.lineNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedRoute!.origin} → ${_selectedRoute!.destination}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datum i vrijeme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Datum',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd.MM.yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getDayName(_selectedDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vrijeme',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sljedeći polazak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tip karte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._ticketTypes.map((type) {
              final isSelected = _selectedTicketType?.id == type.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTicketType = type;
                    _selectedTicketPrice = null;
                  });
                  _loadTicketPrices();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.orange[50] : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.orange[700] : Colors.black87,
                              ),
                            ),
                            if (type.description != null)
                              Text(
                                type.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: Colors.orange[700]),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPriceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cijena karte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._ticketPrices.map((price) {
              final isSelected = _selectedTicketPrice?.id == price.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTicketPrice = price;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.orange[50] : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price.zoneName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.orange[700] : Colors.black87,
                              ),
                            ),
                            if (price.validityDescription.isNotEmpty)
                              Text(
                                price.validityDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${price.price.toStringAsFixed(2)} KM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.orange[700] : Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        const SizedBox(width: 8),
                      if (isSelected)
                        Icon(Icons.check_circle, color: Colors.orange[700]),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTicketPriceMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cijena za ${_selectedTicketType?.name ?? "ovaj tip karte"} trenutno nije dostupna. Molimo kontaktirajte administratora.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Način plaćanja',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('card', 'Kartica', '**** 1234', Icons.credit_card),
            const SizedBox(height: 8),
            _buildPaymentOption('paypal', 'PayPal', 'user@email.com', Icons.payment),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfoCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vaša pretplata pokriva ovu kartu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Karta je besplatna zbog vaše aktivne pretplate (${_activeSubscription?.packageName ?? "pretplata"}).',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, String subtitle, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.orange[50] : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.orange[700] : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange[700] : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.orange[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalji kupovine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Tip karte:', _selectedTicketType?.name ?? 'Nije odabrano'),
            if (_selectedRoute != null)
              _buildSummaryRow('Linija:', _selectedRoute!.transportLineNumber),
            _buildSummaryRow(
              'Ukupno:', 
              _coversSelection
                ? 'Besplatno (pokriva pretplata)'
                : (_selectedTicketPrice != null 
                    ? '${_getTotalPrice().toStringAsFixed(2)} KM'
                    : 'Nije dostupno')
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  Widget _buildPurchaseButton() {
    final bool canPurchase = _selectedTicketType != null && 
                             _selectedRoute != null && 
                             _selectedTicketPrice != null && 
                             !_isPurchasing;
    
    return ElevatedButton(
      onPressed: canPurchase ? _purchaseTicket : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _coversSelection ? Colors.green[700] : Colors.orange[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isPurchasing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _coversSelection ? 'Kreiraj besplatnu kartu' : 'Kupi kartu',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
