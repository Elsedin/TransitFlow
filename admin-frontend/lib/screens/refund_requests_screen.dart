import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refund_request_model.dart';
import '../services/refund_request_service.dart';

class RefundRequestsScreen extends StatefulWidget {
  const RefundRequestsScreen({super.key});

  @override
  State<RefundRequestsScreen> createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  final _service = RefundRequestService();
  bool _isLoading = true;
  String? _error;
  String? _statusFilter = 'pending';
  List<RefundRequest> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.getAll(status: _statusFilter);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resolve(RefundRequest req, {required bool approve}) async {
    final noteController = TextEditingController(text: '');
    final note = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Odobri refund' : 'Odbij refund'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Napomena (opcionalno)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Odustani')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
    if (note == null) return;
    if (!mounted) return;

    try {
      if (approve) {
        await _service.approve(req.id, adminNote: note.isEmpty ? null : note);
      } else {
        await _service.reject(req.id, adminNote: note.isEmpty ? null : note);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Color _chipColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Na čekanju';
      case 'approved':
        return 'Odobren';
      case 'rejected':
        return 'Odbijen';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zahtjevi za refund',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  DropdownButton<String?>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Na čekanju')),
                      DropdownMenuItem(value: 'approved', child: Text('Odobreni')),
                      DropdownMenuItem(value: 'rejected', child: Text('Odbijeni')),
                      DropdownMenuItem(value: null, child: Text('Svi')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _load();
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Osvježi'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: TextStyle(color: Colors.red[700])),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final r = _items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Karta #${r.ticketNumber} • ${r.userEmail}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              label: Text(
                                _statusText(r.status),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _chipColor(r.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('PublicId: ${r.ticketPublicId}'),
                        const SizedBox(height: 8),
                        Text('Poruka: ${r.message}'),
                        const SizedBox(height: 8),
                        Text('Kreirano: ${DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt)}'),
                        if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Napomena admina: ${r.adminNote}'),
                        ],
                        if (r.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _resolve(r, approve: true),
                                icon: const Icon(Icons.check),
                                label: const Text('Odobri'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _resolve(r, approve: false),
                                icon: const Icon(Icons.close),
                                label: const Text('Odbij'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

