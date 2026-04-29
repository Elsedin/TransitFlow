import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/refund_request_service.dart';

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  Timer? _timer;
  Duration? _remainingTime;
  final _refundRequestService = RefundRequestService();

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    if (widget.ticket.isUsed) {
      _remainingTime = null;
      setState(() {});
      return;
    }

    if (now.isBefore(widget.ticket.validFrom)) {
      _remainingTime = widget.ticket.validFrom.difference(now);
      setState(() {});
      return;
    }

    if (now.isAfter(widget.ticket.validTo)) {
      _remainingTime = null;
      setState(() {});
      return;
    }

    _remainingTime = widget.ticket.validTo.difference(now);
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  String _formatDurationLong(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days ${days == 1 ? 'dan' : 'dana'} i $hours ${hours == 1 ? 'sat' : 'sati'}';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'sat' : 'sati'} i $minutes ${minutes == 1 ? 'minut' : 'minuta'}';
    } else {
      return '$minutes ${minutes == 1 ? 'minut' : 'minuta'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isUsed = widget.ticket.isUsed;
    final isRefunded = widget.ticket.isRefunded;
    final isValidatedAtLeastOnce = widget.ticket.usedAt != null;
    final isNotActiveYet = !isUsed && now.isBefore(widget.ticket.validFrom);
    final isExpired = !isUsed && now.isAfter(widget.ticket.validTo);
    final isActive = !isUsed && !isNotActiveYet && !isExpired;
    final canRequestRefund = !isRefunded && !isUsed && !isExpired && !isValidatedAtLeastOnce;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji karte'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTicketHeader(),
            const SizedBox(height: 24),
            _buildQRCodeSection(),
            const SizedBox(height: 16),
            if (isActive) _buildStatusMessage('Karta je aktivna', Icons.check_circle, Colors.green),
            if (isNotActiveYet) _buildStatusMessage('Karta još nije aktivna', Icons.schedule, Colors.orange),
            if (isExpired) _buildStatusMessage('Karta je istekla', Icons.error_outline, Colors.red),
            if (isUsed) _buildStatusMessage('Karta je iskorištena', Icons.verified, Colors.grey),
            if (isRefunded) _buildStatusMessage('Karta je refundovana', Icons.undo, Colors.blueGrey),
            if (!isRefunded && isValidatedAtLeastOnce)
              _buildStatusMessage('Refund nije moguć jer je karta validirana na kontroli', Icons.info_outline, Colors.blueGrey),
            const SizedBox(height: 24),
            _buildTicketInfoCard(),
            if ((isActive || isNotActiveYet) && _remainingTime != null) ...[
              const SizedBox(height: 24),
              _buildCountdownCard(isNotActiveYet: isNotActiveYet),
            ],
            if (canRequestRefund) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestRefund,
                icon: const Icon(Icons.undo),
                label: const Text('Zatraži refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestRefund() async {
    final controller = TextEditingController();
    final message = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zahtjev za refund'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Unesite razlog (obavezno)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Pošalji'),
          ),
        ],
      ),
    );

    if (message == null || message.isEmpty) return;

    try {
      await _refundRequestService.createRefundRequest(
        ticketId: widget.ticket.id,
        message: message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zahtjev za refund je poslan.')),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception: ', '').trim();
      final friendly = raw.toLowerCase().contains('refund nije moguć')
          ? 'Refund na ovu kartu nije moguć.'
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly)),
      );
    }
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.confirmation_number,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            widget.ticket.ticketTypeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.ticket.routeName != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.ticket.routeName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Kupovina: ${DateFormat('dd.MM.yyyy HH:mm').format(widget.ticket.purchasedAt)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Column(
      children: [
        const Text(
          'QR kod za aktivaciju',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: QrImageView(
            data: widget.ticket.publicId,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.ticket.publicId,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kontrolor/Admin provjerava pri ulasku u vozilo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informacije o karti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tip karte:', widget.ticket.ticketTypeName),
            if (widget.ticket.routeName != null)
              _buildInfoRow('Linija:', widget.ticket.routeName!),
            _buildInfoRow(
              'Važi od:',
              dateTimeFormat.format(widget.ticket.validFrom),
            ),
            _buildInfoRow(
              'Važi do:',
              dateTimeFormat.format(widget.ticket.validTo),
            ),
            _buildInfoRow(
              'Cijena:',
              '${widget.ticket.price.toStringAsFixed(2)} KM',
              valueColor: Colors.orange[700],
            ),
            if (widget.ticket.paymentMethod != null)
              _buildInfoRow(
                'Način plaćanja:',
                widget.ticket.paymentMethod == 'Stripe' ? 'Kartica' : widget.ticket.paymentMethod!,
              ),
            _buildInfoRow('Broj karte:', widget.ticket.ticketNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard({required bool isNotActiveYet}) {
    if (_remainingTime == null || _remainingTime!.isNegative) {
      return const SizedBox.shrink();
    }

    final hours = _remainingTime!.inHours;
    final minutes = _remainingTime!.inMinutes % 60;
    final seconds = _remainingTime!.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isNotActiveYet ? 'Aktivira se za:' : 'Preostalo vrijeme:',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preostalo ${_formatDurationLong(_remainingTime!)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
