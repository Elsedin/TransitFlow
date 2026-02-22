import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ticket_price_service.dart';
import '../services/ticket_type_service.dart';
import '../services/zone_service.dart';
import '../models/ticket_price_model.dart';
import '../models/ticket_type_model.dart';
import '../models/station_model.dart';

class TicketPricesScreen extends StatefulWidget {
  const TicketPricesScreen({super.key});

  @override
  State<TicketPricesScreen> createState() => _TicketPricesScreenState();
}

class _TicketPricesScreenState extends State<TicketPricesScreen> {
  final _ticketPriceService = TicketPriceService();
  final _ticketTypeService = TicketTypeService();
  final _zoneService = ZoneService();
  List<TicketPrice> _ticketPrices = [];
  List<TicketPrice> _filteredTicketPrices = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _ticketTypeFilter;
  int? _zoneFilter;
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadTicketPrices();
  }

  Future<void> _loadTicketPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticketPrices = await _ticketPriceService.getAll(
        ticketTypeId: _ticketTypeFilter,
        zoneId: _zoneFilter,
        isActive: _statusFilter,
      );
      setState(() {
        _ticketPrices = ticketPrices;
        _filteredTicketPrices = ticketPrices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ticket prices: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTicketPrices = _ticketPrices.where((price) {
        if (_ticketTypeFilter != null && price.ticketTypeId != _ticketTypeFilter) {
          return false;
        }
        if (_zoneFilter != null && price.zoneId != _zoneFilter) {
          return false;
        }
        if (_statusFilter != null && price.isActive != _statusFilter) {
          return false;
        }
        return true;
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _deleteTicketPrice(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši cijenu'),
        content: const Text('Da li ste sigurni da želite obrisati ovu cijenu?'),
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
        final success = await _ticketPriceService.delete(id);
        if (success) {
          _loadTicketPrices();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cijena uspješno obrisana')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Neuspješno brisanje cijene')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddEditDialog({TicketPrice? ticketPrice}) async {
    await showDialog(
      context: context,
      builder: (context) => _TicketPriceDialog(
        ticketPrice: ticketPrice,
        onSave: () {
          _loadTicketPrices();
        },
      ),
    );
  }

  List<TicketPrice> get _paginatedTicketPrices {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredTicketPrices.length);
    return _filteredTicketPrices.sublist(start, end);
  }

  int get _totalPages => (_filteredTicketPrices.length / _itemsPerPage).ceil();

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
                'Upravljanje cijenama karata',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj novu cijenu'),
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
            'Cijene karata',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: FutureBuilder<List<TicketType>>(
                    future: _ticketTypeService.getAll(isActive: true),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: [],
                            hint: const Text('Učitavanje tipova...'),
                            onChanged: null,
                          ),
                        );
                      }
                      final types = snapshot.data!;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _ticketTypeFilter,
                          hint: const Text('Svi tipovi karata'),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Svi tipovi karata')),
                            ...types.map((type) => DropdownMenuItem<int?>(
                                  value: type.id,
                                  child: Text(type.name),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _ticketTypeFilter = value;
                            });
                            _loadTicketPrices();
                          },
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: FutureBuilder<List<Zone>>(
                    future: _zoneService.getAll(isActive: true),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: [],
                            hint: const Text('Učitavanje zona...'),
                            onChanged: null,
                          ),
                        );
                      }
                      final zones = snapshot.data!;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _zoneFilter,
                          hint: const Text('Sve zone'),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Sve zone')),
                            ...zones.map((zone) => DropdownMenuItem<int?>(
                                  value: zone.id,
                                  child: Text(zone.name),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _zoneFilter = value;
                            });
                            _loadTicketPrices();
                          },
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _statusFilter,
                    hint: const Text('Sve cijene'),
                    icon: const Icon(Icons.filter_list),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Sve cijene')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Aktivne')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Neaktivne')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadTicketPrices();
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
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
    if (_paginatedTicketPrices.isEmpty) {
      return const Center(child: Text('Nema pronađenih cijena'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.0),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.3),
          6: FlexColumnWidth(1.2),
          7: FlexColumnWidth(2.0),
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
              _TableHeaderCell('Tip karte'),
              _TableHeaderCell('Zona'),
              _TableHeaderCell('Cijena (KM)'),
              _TableHeaderCell('Važenje'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Datum kreiranja'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedTicketPrices.asMap().entries.map((entry) {
            final index = entry.key;
            final price = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(price.id.toString()),
                _TableCell(price.ticketTypeName),
                _TableCell(price.zoneName),
                _TableCell('${price.price.toStringAsFixed(2)} KM'),
                _TableCell(price.validityDescription),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        price.isActive ? 'Aktivna' : 'Neaktivna',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: price.isActive ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _TableCell(DateFormat('dd.MM.yyyy').format(price.createdAt)),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(ticketPrice: price),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Uredi'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _deleteTicketPrice(price.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
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
            'Prikazano ${_paginatedTicketPrices.length} od ${_filteredTicketPrices.length} cijena',
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

class _TicketPriceDialog extends StatefulWidget {
  final TicketPrice? ticketPrice;
  final VoidCallback onSave;

  const _TicketPriceDialog({
    this.ticketPrice,
    required this.onSave,
  });

  @override
  State<_TicketPriceDialog> createState() => _TicketPriceDialogState();
}

class _TicketPriceDialogState extends State<_TicketPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ticketPriceService = TicketPriceService();
  final _ticketTypeService = TicketTypeService();
  final _zoneService = ZoneService();
  final _priceController = TextEditingController();
  int? _selectedTicketTypeId;
  int? _selectedZoneId;
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _isActive = true;
  bool _isLoading = false;
  List<TicketType> _ticketTypes = [];
  List<Zone> _zones = [];

  @override
  void initState() {
    super.initState();
    if (widget.ticketPrice != null) {
      _selectedTicketTypeId = widget.ticketPrice!.ticketTypeId;
      _selectedZoneId = widget.ticketPrice!.zoneId;
      _priceController.text = widget.ticketPrice!.price.toStringAsFixed(2);
      _validFrom = widget.ticketPrice!.validFrom;
      _validTo = widget.ticketPrice!.validTo;
      _isActive = widget.ticketPrice!.isActive;
    } else {
      _validFrom = DateTime.now();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final types = await _ticketTypeService.getAll(isActive: true);
      final zones = await _zoneService.getAll(isActive: true);
      setState(() {
        _ticketTypes = types;
        _zones = zones;
        if (widget.ticketPrice == null && _ticketTypes.isNotEmpty && _selectedTicketTypeId == null) {
          _selectedTicketTypeId = _ticketTypes.first.id;
        }
        if (widget.ticketPrice == null && _zones.isNotEmpty && _selectedZoneId == null) {
          _selectedZoneId = _zones.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri učitavanju podataka: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_validFrom ?? DateTime.now()) : (_validTo ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTicketTypeId == null || _selectedZoneId == null || _validFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva polja')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
      if (price == null || price <= 0) {
        throw Exception('Neispravna cijena');
      }

      if (widget.ticketPrice == null) {
        await _ticketPriceService.create(CreateTicketPriceRequest(
          ticketTypeId: _selectedTicketTypeId!,
          zoneId: _selectedZoneId!,
          price: price,
          validFrom: _validFrom!,
          validTo: _validTo,
        ));
      } else {
        await _ticketPriceService.update(widget.ticketPrice!.id, UpdateTicketPriceRequest(
          ticketTypeId: _selectedTicketTypeId!,
          zoneId: _selectedZoneId!,
          price: price,
          validFrom: _validFrom!,
          validTo: _validTo,
          isActive: _isActive,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ticketPrice == null
                ? 'Cijena je uspješno dodata'
                : 'Cijena je uspješno ažurirana'),
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
      title: Text(widget.ticketPrice == null ? 'Dodaj novu cijenu' : 'Uredi cijenu'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedTicketTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Tip karte',
                    border: OutlineInputBorder(),
                  ),
                  items: _ticketTypes.map((type) => DropdownMenuItem<int>(
                        value: type.id,
                        child: Text(type.name),
                      )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTicketTypeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite tip karte';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedZoneId,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    border: OutlineInputBorder(),
                  ),
                  items: _zones.map((zone) => DropdownMenuItem<int>(
                        value: zone.id,
                        child: Text(zone.name),
                      )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedZoneId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite zonu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cijena (KM)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite cijenu';
                    }
                    final price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price <= 0) {
                      return 'Molimo unesite ispravnu cijenu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Važi od',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _validFrom != null
                                ? DateFormat('dd.MM.yyyy').format(_validFrom!)
                                : 'Odaberite datum',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Važi do (opciono)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _validTo != null
                                ? DateFormat('dd.MM.yyyy').format(_validTo!)
                                : 'Neograničeno',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.ticketPrice != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Aktivna'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
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
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
