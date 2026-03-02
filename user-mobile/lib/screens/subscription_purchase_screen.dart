import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'subscription_success_screen.dart';
import 'paypal_payment_screen.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  final SubscriptionPackage? package;
  final Subscription? existingSubscription;

  const SubscriptionPurchaseScreen({
    super.key,
    this.package,
    this.existingSubscription,
  });

  @override
  State<SubscriptionPurchaseScreen> createState() => _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState extends State<SubscriptionPurchaseScreen> {
  final _subscriptionService = SubscriptionService();
  final _paymentService = PaymentService();
  String? _paymentMethod;
  bool _isPurchasing = false;
  String? _errorMessage;

  SubscriptionPackage? get _package {
    if (widget.package != null) return widget.package;
    if (widget.existingSubscription != null) {
      final packages = _subscriptionService.getAvailablePackages();
      try {
        return packages.firstWhere(
          (p) => p.displayName == widget.existingSubscription!.packageName,
        );
      } catch (e) {
        return packages.isNotEmpty ? packages.first : null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_package == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kupovina pretplate'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Paket nije odabran'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSubscription != null ? 'Obnova pretplate' : 'Kupovina pretplate'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPackageInfoCard(),
            const SizedBox(height: 24),
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildPurchaseButton(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _package!.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_package!.durationDays} dana • Neograničen broj vožnji',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ..._package!.benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
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

  Widget _buildPaymentOption(String value, String label, String subtitle, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
          _errorMessage = null;
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
            Icon(icon, color: isSelected ? Colors.orange[700] : Colors.black87),
            const SizedBox(width: 16),
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
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: _package!.durationDays));
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sažetak kupovine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Paket:', _package!.displayName),
            _buildSummaryRow('Početak:', dateFormat.format(startDate)),
            _buildSummaryRow('Kraj:', dateFormat.format(endDate)),
            _buildSummaryRow('Trajanje:', '${_package!.durationDays} dana'),
            _buildSummaryRow(
              'Ukupno:',
              '${_package!.price.toStringAsFixed(2)} KM',
              valueColor: Colors.orange[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final bool canPurchase = _paymentMethod != null && !_isPurchasing;

    return ElevatedButton(
      onPressed: canPurchase ? _purchaseSubscription : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isPurchasing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              widget.existingSubscription != null ? 'Obnovi pretplatu' : 'Kupi pretplatu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _purchaseSubscription() async {
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
          SnackBar(content: Text(_errorMessage ?? 'Greška pri kupovini pretplate')),
        );
      }
    }
  }

  Future<void> _processStripePayment() async {
    try {
      final totalPrice = _package!.price;

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
        await _createSubscriptionAfterPayment(result.transactionId);
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
      final totalPrice = _package!.price;

      final paypalOrder = await _paymentService.createPayPalOrder(totalPrice);

      if (!mounted) return;

      setState(() {
        _errorMessage = null;
      });

      final returnedOrderId = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (context) => PayPalPaymentScreen(
            approvalUrl: paypalOrder.approvalUrl,
            orderId: paypalOrder.orderId,
            onPaymentComplete: (String orderId) {},
            onPaymentCancel: () {},
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
          await _createSubscriptionAfterPayment(paymentResult.transactionId);
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

  Future<void> _createSubscriptionAfterPayment(int transactionId) async {
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: _package!.durationDays));

      final subscription = await _subscriptionService.purchaseSubscription(
        packageName: _package!.displayName,
        price: _package!.price,
        startDate: startDate,
        endDate: endDate,
        status: 'Active',
        transactionId: transactionId,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SubscriptionSuccessScreen(subscription: subscription),
          ),
        );
      }
    } catch (e) {
      throw Exception('Greška pri kreiranju pretplate: $e');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }
}
