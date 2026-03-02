import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';

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
    if (widget.ticket.isActive && !widget.ticket.isUsed) {
      if (widget.ticket.validTo.isAfter(now)) {
        _remainingTime = widget.ticket.validTo.difference(now);
      } else {
        _remainingTime = Duration.zero;
      }
    } else {
      _remainingTime = null;
    }
    setState(() {});
  }

  void _startTimer() {
    if (widget.ticket.isActive && !widget.ticket.isUsed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _calculateRemainingTime();
      });
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
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
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
    final now = DateTime.now();
    final isActive = widget.ticket.isActive && !widget.ticket.isUsed;

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
            if (isActive) _buildQRCodeSection(),
            if (!isActive) _buildInactiveTicketMessage(),
            const SizedBox(height: 24),
            _buildTicketInfoCard(),
            if (isActive && _remainingTime != null) ...[
              const SizedBox(height: 24),
              _buildCountdownCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

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
            data: widget.ticket.ticketNumber,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.ticket.ticketNumber,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Skeniraj prije ulaska u vozilo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveTicketMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.ticket.isUsed ? Colors.grey[100] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.ticket.isUsed ? Colors.grey[300]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.ticket.isUsed ? Icons.check_circle : Icons.error_outline,
            color: widget.ticket.isUsed ? Colors.grey[600] : Colors.red[700],
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.ticket.isUsed
                  ? 'Ova karta je već korištena'
                  : 'Ova karta je istekla',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.ticket.isUsed ? Colors.grey[800] : Colors.red[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    final dateFormat = DateFormat('dd.MM.yyyy');
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
              'Datum i vrijeme:',
              dateTimeFormat.format(widget.ticket.purchasedAt),
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
            _buildInfoRow(
              'Važenje:',
              'Do ${dateTimeFormat.format(widget.ticket.validTo)}',
            ),
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

  Widget _buildCountdownCard() {
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
          const Text(
            'Preostalo vrijeme:',
            style: TextStyle(
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
