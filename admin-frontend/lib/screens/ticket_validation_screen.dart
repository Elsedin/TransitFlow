import 'package:flutter/material.dart';
import '../services/ticket_service.dart';

class TicketValidationScreen extends StatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  State<TicketValidationScreen> createState() => _TicketValidationScreenState();
}

class _TicketValidationScreenState extends State<TicketValidationScreen> {
  final _ticketService = TicketService();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _ticketService.validateTicketByPublicId(code);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String? status, bool? isValid) {
    if (status == null) return Colors.grey;
    if (status == 'Used') return Colors.green;
    if (status == 'Valid') return Colors.green;
    if (status == 'AlreadyUsed') return Colors.orange;
    if (status == 'NotActiveYet') return Colors.orange;
    if (status == 'Expired') return Colors.red;
    if (status == 'NotFound') return Colors.red;
    if (isValid == true) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final status = _result?['status'] as String?;
    final isValid = _result?['isValid'] as bool?;
    final message = _result?['message'] as String?;
    final ticket = _result?['ticket'] as Map<String, dynamic>?;
    final color = _statusColor(status, isValid);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Text(
                'Kontrola karata (Admin/Kontrolor)',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unesite kod iz QR-a (PublicId) i pokrenite validaciju. Ovo simulira skeniranje na ulazu u vozilo.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'QR kod (PublicId)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _validate(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _validate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified),
                label: const Text('Validiraj'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red[800])),
            ),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: color),
                      const SizedBox(width: 8),
                      Text(
                        status ?? 'Rezultat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (message != null) Text(message),
                  const SizedBox(height: 12),
                  if (ticket != null) ...[
                    const Divider(),
                    Text('Broj karte: ${ticket['ticketNumber'] ?? ''}'),
                    Text('Tip: ${ticket['ticketTypeName'] ?? ''}'),
                    Text('Zona: ${ticket['zoneName'] ?? ''}'),
                    if (ticket['routeName'] != null) Text('Ruta: ${ticket['routeName']}'),
                    Text('Važi od: ${ticket['validFrom'] ?? ''}'),
                    Text('Važi do: ${ticket['validTo'] ?? ''}'),
                    Text('Korištena: ${(ticket['isUsed'] == true) ? 'DA' : 'NE'}'),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

