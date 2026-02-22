import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/transport_line_service.dart';
import '../models/transport_line_model.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class TransportLinesScreen extends StatefulWidget {
  const TransportLinesScreen({super.key});

  @override
  State<TransportLinesScreen> createState() => _TransportLinesScreenState();
}

class _TransportLinesScreenState extends State<TransportLinesScreen> {
  final _transportLineService = TransportLineService();
  List<TransportLine> _lines = [];
  List<TransportLine> _filteredLines = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lines = await _transportLineService.getAll(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _statusFilter,
      );
      setState(() {
        _lines = lines;
        _filteredLines = lines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load transport lines: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredLines = _lines.where((line) {
        if (_statusFilter != null && line.isActive != _statusFilter) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return line.lineNumber.toLowerCase().contains(query) ||
              line.name.toLowerCase().contains(query) ||
              line.origin.toLowerCase().contains(query) ||
              line.destination.toLowerCase().contains(query);
        }
        return true;
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _deleteLine(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transport Line'),
        content: const Text('Are you sure you want to delete this transport line?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _transportLineService.delete(id);
        if (success) {
          _loadLines();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transport line deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete transport line')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddEditDialog({TransportLine? line}) async {
    await showDialog(
      context: context,
      builder: (context) => _TransportLineDialog(
        line: line,
        onSave: () {
          _loadLines();
        },
      ),
    );
  }

  List<TransportLine> get _paginatedLines {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredLines.length);
    return _filteredLines.sublist(start, end);
  }

  int get _totalPages => (_filteredLines.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upravljanje linijama',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj novu liniju'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sve linije',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Pretraži linije...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButton<bool?>(
                          value: _statusFilter,
                          hint: const Text('Sve linije'),
                          items: const [
                            DropdownMenuItem<bool?>(value: null, child: Text('Sve linije')),
                            DropdownMenuItem<bool?>(value: true, child: Text('Aktivne')),
                            DropdownMenuItem<bool?>(value: false, child: Text('Neaktivne')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value;
                            });
                            _applyFilters();
                          },
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          underline: const SizedBox(),
                          isExpanded: false,
                          icon: Icon(Icons.filter_list, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(child: Text(_errorMessage!))
                            : _buildTable(),
                  ),
                  if (!_isLoading && _errorMessage == null) _buildPagination(),
                ],
              ),
    );
  }

  Widget _buildTable() {
    if (_paginatedLines.isEmpty) {
      return const Center(child: Text('No transport lines found'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(1.0),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.0),
          6: FlexColumnWidth(1.3),
          7: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: const [
              _TableHeaderCell('ID'),
              _TableHeaderCell('Broj linije'),
              _TableHeaderCell('Naziv'),
              _TableHeaderCell('Polazište'),
              _TableHeaderCell('Odredište'),
              _TableHeaderCell('Tip vozila'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedLines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(line.id.toString()),
                _TableCell(line.lineNumber),
                _TableCell(line.name),
                _TableCell(line.origin),
                _TableCell(line.destination),
                _TableCell(line.transportTypeName),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        line.isActive ? 'Aktivna' : 'Neaktivna',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: line.isActive ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(line: line),
                        child: const Text('Uredi'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _deleteLine(line.id),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Obriši'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Prikazano ${_paginatedLines.length} od ${_filteredLines.length} linija',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                child: const Text('Prethodna'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                child: const Text('Sljedeća'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? child;

  const _TableCell(this.text, {this.color, this.child});

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }
}

class _TransportLineDialog extends StatefulWidget {
  final TransportLine? line;
  final VoidCallback onSave;

  const _TransportLineDialog({
    this.line,
    required this.onSave,
  });

  @override
  State<_TransportLineDialog> createState() => _TransportLineDialogState();
}

class _TransportLineDialogState extends State<_TransportLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lineNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  int? _selectedTransportTypeId;
  bool _isActive = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _transportTypes = [];

  @override
  void initState() {
    super.initState();
    if (widget.line != null) {
      _lineNumberController.text = widget.line!.lineNumber;
      _nameController.text = widget.line!.name;
      _originController.text = widget.line!.origin;
      _destinationController.text = widget.line!.destination;
      _isActive = widget.line!.isActive;
    }
    _loadTransportTypes();
  }

  Future<void> _loadTransportTypes() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/transporttypes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _transportTypes = data.map((item) {
          final map = item as Map<String, dynamic>;
          return {'id': map['id'] as int, 'name': map['name'] as String};
        }).toList();
      } else {
        _transportTypes = [
          {'id': 1, 'name': 'Autobus'},
          {'id': 2, 'name': 'Tramvaj'},
          {'id': 3, 'name': 'Trolejbus'},
        ];
      }
    } catch (e) {
      _transportTypes = [
        {'id': 1, 'name': 'Autobus'},
        {'id': 2, 'name': 'Tramvaj'},
        {'id': 3, 'name': 'Trolejbus'},
      ];
    }

    if (widget.line != null) {
      final type = _transportTypes.firstWhere(
        (t) => t['name'] == widget.line!.transportTypeName,
        orElse: () => _transportTypes.first,
      );
      _selectedTransportTypeId = type['id'] as int;
    } else {
      _selectedTransportTypeId = _transportTypes.isNotEmpty ? _transportTypes.first['id'] as int : null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _lineNumberController.dispose();
    _nameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = TransportLineService();
      if (widget.line == null) {
        await service.create(CreateTransportLineRequest(
          lineNumber: _lineNumberController.text.trim(),
          name: _nameController.text.trim(),
          transportTypeId: _selectedTransportTypeId!,
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          distance: double.tryParse(_distanceController.text) ?? 0.0,
          estimatedDurationMinutes: int.tryParse(_durationController.text) ?? 0,
          isActive: _isActive,
        ));
      } else {
        await service.update(widget.line!.id, UpdateTransportLineRequest(
          lineNumber: _lineNumberController.text.trim(),
          name: _nameController.text.trim(),
          transportTypeId: _selectedTransportTypeId!,
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          distance: double.tryParse(_distanceController.text) ?? 0.0,
          estimatedDurationMinutes: int.tryParse(_durationController.text) ?? 0,
          isActive: _isActive,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.line == null
                ? 'Transport line created successfully'
                : 'Transport line updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.line == null ? 'Dodaj novu liniju' : 'Uredi liniju'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lineNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Broj linije',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter line number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedTransportTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Tip vozila',
                    border: OutlineInputBorder(),
                  ),
                  items: _transportTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'] as int,
                      child: Text(type['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransportTypeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select transport type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _originController,
                  decoration: const InputDecoration(
                    labelText: 'Polazište',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter origin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Odredište',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Udaljenost (km)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Trajanje (min)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Aktivna'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
