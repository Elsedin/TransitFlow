import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/vehicle_service.dart';
import '../services/transport_line_service.dart';
import '../models/vehicle_model.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _vehicleService = VehicleService();
  final _transportLineService = TransportLineService();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleService.getAll(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _statusFilter,
      );
      setState(() {
        _vehicles = vehicles;
        _filteredVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load vehicles: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        if (_statusFilter != null && vehicle.isActive != _statusFilter) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return vehicle.licensePlate.toLowerCase().contains(query) ||
              (vehicle.make != null && vehicle.make!.toLowerCase().contains(query)) ||
              (vehicle.model != null && vehicle.model!.toLowerCase().contains(query)) ||
              vehicle.transportTypeName.toLowerCase().contains(query);
        }
        return true;
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _deleteVehicle(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši vozilo'),
        content: const Text('Da li ste sigurni da želite obrisati ovo vozilo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _vehicleService.delete(id);
        if (success) {
          _loadVehicles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vozilo je uspješno obrisano')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Neuspješno brisanje vozila')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddEditDialog({Vehicle? vehicle}) async {
    await showDialog(
      context: context,
      builder: (context) => _VehicleDialog(
        vehicle: vehicle,
        onSave: () {
          _loadVehicles();
        },
      ),
    );
  }

  List<Vehicle> get _paginatedVehicles {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredVehicles.length);
    return _filteredVehicles.sublist(start, end);
  }

  int get _totalPages => (_filteredVehicles.length / _itemsPerPage).ceil();

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
                'Upravljanje vozilima',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj novo vozilo'),
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
            'Sva vozila',
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
                    hintText: 'Pretraži vozila...',
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
                  hint: const Text('Sva vozila'),
                  items: const [
                    DropdownMenuItem<bool?>(value: null, child: Text('Sva vozila')),
                    DropdownMenuItem<bool?>(value: true, child: Text('Aktivna')),
                    DropdownMenuItem<bool?>(value: false, child: Text('Neaktivna')),
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
    if (_paginatedVehicles.isEmpty) {
      return const Center(child: Text('Nema vozila'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.0),
          4: FlexColumnWidth(0.8),
          5: FlexColumnWidth(0.8),
          6: FlexColumnWidth(1.2),
          7: FlexColumnWidth(1.3),
          8: FlexColumnWidth(1.5),
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
              _TableHeaderCell('Registarska oznaka'),
              _TableHeaderCell('Marka'),
              _TableHeaderCell('Model'),
              _TableHeaderCell('Godina'),
              _TableHeaderCell('Kapacitet'),
              _TableHeaderCell('Tip vozila'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedVehicles.asMap().entries.map((entry) {
            final index = entry.key;
            final vehicle = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(vehicle.id.toString()),
                _TableCell(vehicle.licensePlate),
                _TableCell(vehicle.make ?? '-'),
                _TableCell(vehicle.model ?? '-'),
                _TableCell(vehicle.year?.toString() ?? '-'),
                _TableCell(vehicle.capacity.toString()),
                _TableCell(vehicle.transportTypeName),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        vehicle.isActive ? 'Aktivno' : 'Neaktivno',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: vehicle.isActive ? Colors.green : Colors.red,
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
                        onPressed: () => _showAddEditDialog(vehicle: vehicle),
                        child: const Text('Uredi'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _deleteVehicle(vehicle.id),
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
            'Prikazano ${_paginatedVehicles.length} od ${_filteredVehicles.length} vozila',
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

class _VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;
  final VoidCallback onSave;

  const _VehicleDialog({
    this.vehicle,
    required this.onSave,
  });

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _capacityController = TextEditingController();
  int? _selectedTransportTypeId;
  bool _isActive = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _transportTypes = [];

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _licensePlateController.text = widget.vehicle!.licensePlate;
      _makeController.text = widget.vehicle!.make ?? '';
      _modelController.text = widget.vehicle!.model ?? '';
      _yearController.text = widget.vehicle!.year?.toString() ?? '';
      _capacityController.text = widget.vehicle!.capacity.toString();
      _selectedTransportTypeId = widget.vehicle!.transportTypeId;
      _isActive = widget.vehicle!.isActive;
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

    if (widget.vehicle == null) {
      _selectedTransportTypeId = _transportTypes.isNotEmpty ? _transportTypes.first['id'] as int : null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _capacityController.dispose();
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
      final service = VehicleService();
      if (widget.vehicle == null) {
        await service.create(CreateVehicleRequest(
          licensePlate: _licensePlateController.text.trim(),
          make: _makeController.text.trim().isEmpty ? null : _makeController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          year: _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text),
          capacity: int.tryParse(_capacityController.text) ?? 0,
          transportTypeId: _selectedTransportTypeId!,
        ));
      } else {
        await service.update(widget.vehicle!.id, UpdateVehicleRequest(
          licensePlate: _licensePlateController.text.trim(),
          make: _makeController.text.trim().isEmpty ? null : _makeController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          year: _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text),
          capacity: int.tryParse(_capacityController.text) ?? 0,
          transportTypeId: _selectedTransportTypeId!,
          isActive: _isActive,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle == null
                ? 'Vozilo je uspješno dodato'
                : 'Vozilo je uspješno ažurirano'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
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
      title: Text(widget.vehicle == null ? 'Dodaj novo vozilo' : 'Uredi vozilo'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Registarska oznaka',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite registarsku oznaku';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _makeController,
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Godina',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Kapacitet',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Molimo unesite kapacitet';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity <= 0) {
                            return 'Kapacitet mora biti pozitivan broj';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                      return 'Molimo izaberite tip vozila';
                    }
                    return null;
                  },
                ),
                if (widget.vehicle != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Aktivno'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Otkaži'),
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
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
