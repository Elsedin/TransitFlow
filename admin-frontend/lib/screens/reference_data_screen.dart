import 'package:flutter/material.dart';
import '../services/zone_service.dart';
import '../services/city_service.dart';
import '../services/ticket_type_service.dart';
import '../services/transport_type_service.dart';
import '../models/station_model.dart';
import '../models/ticket_type_model.dart';
import '../models/transport_type_model.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen> {
  String _selectedCategory = 'zones';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upravljanje referentnim podacima',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryCards(),
          const SizedBox(height: 32),
          _buildCategoryContent(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildCategoryCard(
          'Tipovi karata',
          Icons.confirmation_number,
          'ticketTypes',
          Colors.blue,
          'Upravljanje tipovima karata',
        ),
        _buildCategoryCard(
          'Zone',
          Icons.location_on,
          'zones',
          Colors.green,
          'Upravljanje zonama',
        ),
        _buildCategoryCard(
          'Gradovi',
          Icons.location_city,
          'cities',
          Colors.amber,
          'Upravljanje gradovima',
        ),
        _buildCategoryCard(
          'Tipovi vozila',
          Icons.directions_bus,
          'transportTypes',
          Colors.red,
          'Upravljanje tipovima vozila',
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    String category,
    Color color,
    String description,
  ) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 2,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.orange, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.orange : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'zones':
        return ZonesTable();
      case 'ticketTypes':
        return TicketTypesTable();
      case 'transportTypes':
        return TransportTypesTable();
      case 'cities':
        return CitiesTable();
      default:
        return ZonesTable();
    }
  }
}

class ZonesTable extends StatefulWidget {
  @override
  State<ZonesTable> createState() => _ZonesTableState();
}

class _ZonesTableState extends State<ZonesTable> {
  final _zoneService = ZoneService();
  List<Zone> _zones = [];
  List<Zone> _filteredZones = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final zones = await _zoneService.getAll();
      setState(() {
        _zones = zones;
        _filteredZones = zones;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Zone> filtered = List.from(_zones);

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((zone) {
        return zone.name.toLowerCase().contains(search) ||
            (zone.description != null && zone.description!.toLowerCase().contains(search));
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((zone) => zone.isActive == _statusFilter).toList();
    }

    setState(() {
      _filteredZones = filtered;
      _currentPage = 0;
    });
  }

  List<Zone> get _paginatedZones {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredZones.length);
    return _filteredZones.sublist(start, end);
  }

  Future<void> _showAddEditDialog({Zone? zone}) async {
    final nameController = TextEditingController(text: zone?.name ?? '');
    final descriptionController = TextEditingController(text: zone?.description ?? '');
    bool isActive = zone?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(zone == null ? 'Dodaj zonu' : 'Uredi zonu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (zone != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Aktivna'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv je obavezan')),
                  );
                  return;
                }

                try {
                  if (zone == null) {
                    await _zoneService.create(CreateZoneRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    ));
                  } else {
                    await _zoneService.update(zone.id, UpdateZoneRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      isActive: isActive,
                    ));
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(zone == null ? 'Zona je uspješno dodana' : 'Zona je uspješno ažurirana'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Greška: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteZone(Zone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati zonu "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _zoneService.delete(zone.id);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zona je uspješno obrisana')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Zone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži zone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
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
                      hint: const Text('Svi statusi'),
                      icon: const Icon(Icons.filter_list),
                      items: const [
                        DropdownMenuItem<bool?>(value: null, child: Text('Svi statusi')),
                        DropdownMenuItem<bool?>(value: true, child: Text('Aktivne')),
                        DropdownMenuItem<bool?>(value: false, child: Text('Neaktivne')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj zonu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      _buildTable(),
                      const SizedBox(height: 20),
                      _buildPagination(),
                    ],
                  ),
      ],
    );
  }

  Widget _buildTable() {
    if (_paginatedZones.isEmpty) {
      return const Center(child: Text('Nema pronađenih zona'));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2.0),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.2),
        6: FlexColumnWidth(1.5),
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
            _TableHeaderCell('Naziv'),
            _TableHeaderCell('Kod'),
            _TableHeaderCell('Opis'),
            _TableHeaderCell('Broj stanica'),
            _TableHeaderCell('Status'),
            _TableHeaderCell('Akcije'),
          ],
        ),
        ..._paginatedZones.map((zone) => TableRow(
              children: [
                _TableCell(zone.id.toString()),
                _TableCell(zone.name),
                _TableCell(zone.name.toUpperCase().replaceAll(' ', '_')),
                _TableCell(zone.description ?? ''),
                _TableCell(zone.stationCount.toString()),
                _TableCell(zone.isActive ? 'Aktivna' : 'Neaktivna'),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(zone: zone),
                        child: const Text('Uredi'),
                      ),
                      TextButton(
                        onPressed: () => _deleteZone(zone),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Obriši'),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredZones.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica ${_currentPage + 1} od $totalPages'),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Widget? child;

  const _TableCell(this.text, {this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: child ?? Text(
        text,
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class TicketTypesTable extends StatefulWidget {
  @override
  State<TicketTypesTable> createState() => _TicketTypesTableState();
}

class _TicketTypesTableState extends State<TicketTypesTable> {
  final _ticketTypeService = TicketTypeService();
  List<TicketType> _ticketTypes = [];
  List<TicketType> _filteredTicketTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticketTypes = await _ticketTypeService.getAll();
      setState(() {
        _ticketTypes = ticketTypes;
        _filteredTicketTypes = ticketTypes;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<TicketType> filtered = List.from(_ticketTypes);

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((type) {
        return type.name.toLowerCase().contains(search) ||
            (type.description != null && type.description!.toLowerCase().contains(search));
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((type) => type.isActive == _statusFilter).toList();
    }

    setState(() {
      _filteredTicketTypes = filtered;
      _currentPage = 0;
    });
  }

  List<TicketType> get _paginatedTicketTypes {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredTicketTypes.length);
    return _filteredTicketTypes.sublist(start, end);
  }

  Future<void> _showAddEditDialog({TicketType? ticketType}) async {
    final nameController = TextEditingController(text: ticketType?.name ?? '');
    final descriptionController = TextEditingController(text: ticketType?.description ?? '');
    final validityDaysController = TextEditingController(text: ticketType?.validityDays.toString() ?? '30');
    bool isActive = ticketType?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ticketType == null ? 'Dodaj tip karte' : 'Uredi tip karte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: validityDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Broj dana važenja *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (ticketType != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Aktivna'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv je obavezan')),
                  );
                  return;
                }

                final validityDays = int.tryParse(validityDaysController.text.trim());
                if (validityDays == null || validityDays <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broj dana važenja mora biti pozitivan broj')),
                  );
                  return;
                }

                try {
                  if (ticketType == null) {
                    await _ticketTypeService.create(CreateTicketTypeRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      validityDays: validityDays,
                    ));
                  } else {
                    await _ticketTypeService.update(ticketType.id, UpdateTicketTypeRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      validityDays: validityDays,
                      isActive: isActive,
                    ));
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ticketType == null ? 'Tip karte je uspješno dodan' : 'Tip karte je uspješno ažuriran'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Greška: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTicketType(TicketType ticketType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati tip karte "${ticketType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ticketTypeService.delete(ticketType.id);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tip karte je uspješno obrisan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tipovi karata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži tipove karata...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
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
                      hint: const Text('Svi statusi'),
                      icon: const Icon(Icons.filter_list),
                      items: const [
                        DropdownMenuItem<bool?>(value: null, child: Text('Svi statusi')),
                        DropdownMenuItem<bool?>(value: true, child: Text('Aktivni')),
                        DropdownMenuItem<bool?>(value: false, child: Text('Neaktivni')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj tip karte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      _buildTable(),
                      const SizedBox(height: 20),
                      _buildPagination(),
                    ],
                  ),
      ],
    );
  }

  Widget _buildTable() {
    if (_paginatedTicketTypes.isEmpty) {
      return const Center(child: Text('Nema pronađenih tipova karata'));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(2.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.5),
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
            _TableHeaderCell('Naziv'),
            _TableHeaderCell('Opis'),
            _TableHeaderCell('Dana važenja'),
            _TableHeaderCell('Status'),
            _TableHeaderCell('Akcije'),
          ],
        ),
        ..._paginatedTicketTypes.map((type) => TableRow(
              children: [
                _TableCell(type.id.toString()),
                _TableCell(type.name),
                _TableCell(type.description ?? ''),
                _TableCell(type.validityDays.toString()),
                _TableCell(type.isActive ? 'Aktivna' : 'Neaktivna'),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(ticketType: type),
                        child: const Text('Uredi'),
                      ),
                      TextButton(
                        onPressed: () => _deleteTicketType(type),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Obriši'),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredTicketTypes.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica ${_currentPage + 1} od $totalPages'),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class TransportTypesTable extends StatefulWidget {
  @override
  State<TransportTypesTable> createState() => _TransportTypesTableState();
}

class _TransportTypesTableState extends State<TransportTypesTable> {
  final _transportTypeService = TransportTypeService();
  List<TransportType> _transportTypes = [];
  List<TransportType> _filteredTransportTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transportTypes = await _transportTypeService.getAll();
      setState(() {
        _transportTypes = transportTypes;
        _filteredTransportTypes = transportTypes;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<TransportType> filtered = List.from(_transportTypes);

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((type) {
        return type.name.toLowerCase().contains(search) ||
            (type.description != null && type.description!.toLowerCase().contains(search));
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((type) => type.isActive == _statusFilter).toList();
    }

    setState(() {
      _filteredTransportTypes = filtered;
      _currentPage = 0;
    });
  }

  List<TransportType> get _paginatedTransportTypes {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredTransportTypes.length);
    return _filteredTransportTypes.sublist(start, end);
  }

  Future<void> _showAddEditDialog({TransportType? transportType}) async {
    final nameController = TextEditingController(text: transportType?.name ?? '');
    final descriptionController = TextEditingController(text: transportType?.description ?? '');
    bool isActive = transportType?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(transportType == null ? 'Dodaj tip vozila' : 'Uredi tip vozila'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (transportType != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Aktivna'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv je obavezan')),
                  );
                  return;
                }

                try {
                  if (transportType == null) {
                    await _transportTypeService.create(CreateTransportTypeRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    ));
                  } else {
                    await _transportTypeService.update(transportType.id, UpdateTransportTypeRequest(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      isActive: isActive,
                    ));
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(transportType == null ? 'Tip vozila je uspješno dodan' : 'Tip vozila je uspješno ažuriran'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Greška: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransportType(TransportType transportType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati tip vozila "${transportType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transportTypeService.delete(transportType.id);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tip vozila je uspješno obrisan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tipovi vozila',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži tipove vozila...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
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
                      hint: const Text('Svi statusi'),
                      icon: const Icon(Icons.filter_list),
                      items: const [
                        DropdownMenuItem<bool?>(value: null, child: Text('Svi statusi')),
                        DropdownMenuItem<bool?>(value: true, child: Text('Aktivni')),
                        DropdownMenuItem<bool?>(value: false, child: Text('Neaktivni')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj tip vozila'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      _buildTable(),
                      const SizedBox(height: 20),
                      _buildPagination(),
                    ],
                  ),
      ],
    );
  }

  Widget _buildTable() {
    if (_paginatedTransportTypes.isEmpty) {
      return const Center(child: Text('Nema pronađenih tipova vozila'));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(3.0),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.5),
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
            _TableHeaderCell('Naziv'),
            _TableHeaderCell('Opis'),
            _TableHeaderCell('Status'),
            _TableHeaderCell('Akcije'),
          ],
        ),
        ..._paginatedTransportTypes.map((type) => TableRow(
              children: [
                _TableCell(type.id.toString()),
                _TableCell(type.name),
                _TableCell(type.description ?? ''),
                _TableCell(type.isActive ? 'Aktivna' : 'Neaktivna'),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(transportType: type),
                        child: const Text('Uredi'),
                      ),
                      TextButton(
                        onPressed: () => _deleteTransportType(type),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Obriši'),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredTransportTypes.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica ${_currentPage + 1} od $totalPages'),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class CitiesTable extends StatefulWidget {
  @override
  State<CitiesTable> createState() => _CitiesTableState();
}

class _CitiesTableState extends State<CitiesTable> {
  final _cityService = CityService();
  List<City> _cities = [];
  List<City> _filteredCities = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cities = await _cityService.getAll();
      setState(() {
        _cities = cities;
        _filteredCities = cities;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Greška: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<City> filtered = List.from(_cities);

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((city) {
        return city.name.toLowerCase().contains(search) ||
            (city.postalCode != null && city.postalCode!.toLowerCase().contains(search)) ||
            city.countryName.toLowerCase().contains(search);
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((city) => city.isActive == _statusFilter).toList();
    }

    setState(() {
      _filteredCities = filtered;
      _currentPage = 0;
    });
  }

  List<City> get _paginatedCities {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredCities.length);
    return _filteredCities.sublist(start, end);
  }

  Future<void> _showAddEditDialog({City? city}) async {
    final nameController = TextEditingController(text: city?.name ?? '');
    final postalCodeController = TextEditingController(text: city?.postalCode ?? '');
    int? selectedCountryId = city?.countryId;
    bool isActive = city?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(city == null ? 'Dodaj grad' : 'Uredi grad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Naziv *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Poštanski broj',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCountryId,
                  decoration: const InputDecoration(
                    labelText: 'Država',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Nije odabrano'),
                    ),
                    const DropdownMenuItem<int>(
                      value: 1,
                      child: Text('Bosna i Hercegovina'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCountryId = value;
                    });
                  },
                ),
                if (city != null) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Aktivna'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naziv je obavezan')),
                  );
                  return;
                }

                try {
                  if (city == null) {
                    await _cityService.create(CreateCityRequest(
                      name: nameController.text.trim(),
                      postalCode: postalCodeController.text.trim().isEmpty
                          ? null
                          : postalCodeController.text.trim(),
                      countryId: selectedCountryId,
                    ));
                  } else {
                    await _cityService.update(city.id, UpdateCityRequest(
                      name: nameController.text.trim(),
                      postalCode: postalCodeController.text.trim().isEmpty
                          ? null
                          : postalCodeController.text.trim(),
                      countryId: selectedCountryId,
                      isActive: isActive,
                    ));
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(city == null ? 'Grad je uspješno dodan' : 'Grad je uspješno ažuriran'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Greška: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCity(City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati grad "${city.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cityService.delete(city.id);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grad je uspješno obrisan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gradovi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži gradove...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
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
                      hint: const Text('Svi statusi'),
                      icon: const Icon(Icons.filter_list),
                      items: const [
                        DropdownMenuItem<bool?>(value: null, child: Text('Svi statusi')),
                        DropdownMenuItem<bool?>(value: true, child: Text('Aktivni')),
                        DropdownMenuItem<bool?>(value: false, child: Text('Neaktivni')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj grad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      _buildTable(),
                      const SizedBox(height: 20),
                      _buildPagination(),
                    ],
                  ),
      ],
    );
  }

  Widget _buildTable() {
    if (_paginatedCities.isEmpty) {
      return const Center(child: Text('Nema pronađenih gradova'));
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.0),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2.0),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.5),
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
            _TableHeaderCell('Naziv'),
            _TableHeaderCell('Poštanski broj'),
            _TableHeaderCell('Država'),
            _TableHeaderCell('Status'),
            _TableHeaderCell('Akcije'),
          ],
        ),
        ..._paginatedCities.map((city) => TableRow(
              children: [
                _TableCell(city.id.toString()),
                _TableCell(city.name),
                _TableCell(city.postalCode ?? ''),
                _TableCell(city.countryName),
                _TableCell(city.isActive ? 'Aktivna' : 'Neaktivna'),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(city: city),
                        child: const Text('Uredi'),
                      ),
                      TextButton(
                        onPressed: () => _deleteCity(city),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Obriši'),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_filteredCities.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica ${_currentPage + 1} od $totalPages'),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
