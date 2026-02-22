import 'package:flutter/material.dart';
import '../services/route_service.dart';
import '../services/station_service.dart';
import '../services/city_service.dart';
import '../services/zone_service.dart';
import '../services/transport_line_service.dart';
import '../models/route_model.dart' as route_models;
import '../models/station_model.dart';
import '../models/transport_line_model.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _routeService = RouteService();
  final _stationService = StationService();
  final _cityService = CityService();
  final _zoneService = ZoneService();
  final _transportLineService = TransportLineService();
  
  List<route_models.Route> _routes = [];
  List<route_models.Route> _filteredRoutes = [];
  route_models.Route? _selectedRoute;
  List<Station> _stations = [];
  List<City> _cities = [];
  List<Zone> _zones = [];
  List<TransportLine> _transportLines = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool? _statusFilter;

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
      final routes = await _routeService.getAll(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _statusFilter,
      );
      final stations = await _stationService.getAll(isActive: true);
      final cities = await _cityService.getAll(isActive: true);
      final zones = await _zoneService.getAll(isActive: true);
      final transportLines = await _transportLineService.getAll(isActive: true);
      
      setState(() {
        _routes = routes;
        _filteredRoutes = routes;
        _stations = stations;
        _cities = cities;
        _zones = zones;
        _transportLines = transportLines;
        _isLoading = false;
        if (_routes.isNotEmpty && _selectedRoute == null) {
          _selectedRoute = _routes.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRoutes = _routes.where((route) {
        if (_statusFilter != null && route.isActive != _statusFilter) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return route.name.toLowerCase().contains(query) ||
              route.origin.toLowerCase().contains(query) ||
              route.destination.toLowerCase().contains(query) ||
              route.transportLineNumber.toLowerCase().contains(query);
        }
        return true;
      }).toList();
    });
  }

  Future<void> _deleteRoute(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rutu'),
        content: const Text('Da li ste sigurni da želite obrisati ovu rutu?'),
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
        final success = await _routeService.delete(id);
        if (success) {
          if (_selectedRoute?.id == id) {
            _selectedRoute = null;
          }
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ruta je uspješno obrisana')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri brisanju rute: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upravljanje rutama',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(null),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj novu rutu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRoutesList(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildRouteDetails(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rute',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Pretraži rute...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _filteredRoutes.isEmpty
                          ? const Center(child: Text('Nema ruta'))
                          : ListView.builder(
                              itemCount: _filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final route = _filteredRoutes[index];
                                final isSelected = _selectedRoute?.id == route.id;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRoute = route;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.orange[100] : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? Border.all(color: Colors.orange[700]!, width: 2)
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          route.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.orange[700] : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${route.origin} - ${route.destination}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails() {
    if (_selectedRoute == null) {
      return Card(
        elevation: 2,
        child: Center(
          child: Text(
            'Izaberite rutu za prikaz detalja',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalji rute: ${_selectedRoute!.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditDialog(_selectedRoute),
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteRoute(_selectedRoute!.id),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailField('Naziv rute', _selectedRoute!.name),
                    const SizedBox(height: 16),
                    _buildDetailField('Polazište', _selectedRoute!.origin),
                    const SizedBox(height: 16),
                    _buildDetailField('Odredište', _selectedRoute!.destination),
                    const SizedBox(height: 16),
                    _buildDetailField('Linija', _selectedRoute!.transportLineName),
                    const SizedBox(height: 24),
                    Text(
                      'Stajališta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._selectedRoute!.stations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final station = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.stationName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (station.stationAddress != null)
                                    Text(
                                      station.stationAddress!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddEditDialog(route_models.Route? route) async {
    final originController = TextEditingController(text: route?.origin ?? '');
    final destinationController = TextEditingController(text: route?.destination ?? '');
    final distanceController = TextEditingController(text: route?.distance.toString() ?? '0');
    final durationController = TextEditingController(text: route?.estimatedDurationMinutes.toString() ?? '0');
    
    int? selectedTransportLineId = route?.transportLineId;
    bool isActive = route?.isActive ?? true;
    
    List<route_models.RouteStation> routeStations = route?.stations.toList() ?? [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(route == null ? 'Dodaj novu rutu' : 'Uredi rutu'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: originController,
                    decoration: const InputDecoration(
                      labelText: 'Polazište',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Odredište',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedTransportLineId,
                    decoration: const InputDecoration(
                      labelText: 'Linija',
                      border: OutlineInputBorder(),
                    ),
                    items: _transportLines.map((line) {
                      return DropdownMenuItem<int>(
                        value: line.id,
                        child: Text('${line.lineNumber} - ${line.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTransportLineId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          decoration: const InputDecoration(
                            labelText: 'Udaljenost (km)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: durationController,
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
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stajališta',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddStationDialog(setDialogState, routeStations),
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj stajalište'),
                      ),
                    ],
                  ),
                  ...routeStations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final station = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text('${index + 1}.'),
                          const SizedBox(width: 8),
                          Expanded(child: Text(station.stationName)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            onPressed: () {
                              setDialogState(() {
                                routeStations.removeAt(index);
                                for (var i = 0; i < routeStations.length; i++) {
                                  routeStations[i] = route_models.RouteStation(
                                    id: routeStations[i].id,
                                    stationId: routeStations[i].stationId,
                                    stationName: routeStations[i].stationName,
                                    stationAddress: routeStations[i].stationAddress,
                                    order: i + 1,
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (originController.text.isEmpty ||
                    destinationController.text.isEmpty ||
                    selectedTransportLineId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Molimo popunite sva obavezna polja')),
                  );
                  return;
                }

                try {
                  if (route == null) {
                    final createRequest = route_models.CreateRouteRequest(
                      origin: originController.text,
                      destination: destinationController.text,
                      transportLineId: selectedTransportLineId!,
                      distance: double.tryParse(distanceController.text) ?? 0,
                      estimatedDurationMinutes: int.tryParse(durationController.text) ?? 0,
                      stations: routeStations.asMap().entries.map((entry) {
                        return route_models.CreateRouteStationRequest(
                          stationId: entry.value.stationId,
                          order: entry.key + 1,
                        );
                      }).toList(),
                    );
                    await _routeService.create(createRequest);
                  } else {
                    final updateRequest = route_models.UpdateRouteRequest(
                      origin: originController.text,
                      destination: destinationController.text,
                      transportLineId: selectedTransportLineId!,
                      distance: double.tryParse(distanceController.text) ?? 0,
                      estimatedDurationMinutes: int.tryParse(durationController.text) ?? 0,
                      isActive: isActive,
                      stations: routeStations.asMap().entries.map((entry) {
                        return route_models.UpdateRouteStationRequest(
                          id: entry.value.id,
                          stationId: entry.value.stationId,
                          order: entry.key + 1,
                        );
                      }).toList(),
                    );
                    await _routeService.update(route.id, updateRequest);
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(route == null ? 'Ruta je uspješno dodata' : 'Ruta je uspješno ažurirana'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Greška: $e')),
                    );
                  }
                }
              },
              child: Text(route == null ? 'Dodaj' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStationDialog(StateSetter setDialogState, List<route_models.RouteStation> routeStations) async {
    int? selectedStationId = _stations
        .where((station) => !routeStations.any((rs) => rs.stationId == station.id))
        .isNotEmpty
        ? _stations.where((station) => !routeStations.any((rs) => rs.stationId == station.id)).first.id
        : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerState) => AlertDialog(
          title: const Text('Dodaj stajalište'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Izaberi postojeće stajalište'),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _showCreateStationDialog(setDialogState, routeStations);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Novo stajalište'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedStationId,
                  decoration: const InputDecoration(
                    labelText: 'Stajalište',
                    border: OutlineInputBorder(),
                  ),
                  items: _stations
                      .where((station) => !routeStations.any((rs) => rs.stationId == station.id))
                      .map((station) {
                    return DropdownMenuItem<int>(
                      value: station.id,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setInnerState(() {
                      selectedStationId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStationId != null) {
                  final station = _stations.firstWhere((s) => s.id == selectedStationId);
                  setDialogState(() {
                    routeStations.add(route_models.RouteStation(
                      stationId: station.id,
                      stationName: station.name,
                      stationAddress: station.address,
                      order: routeStations.length + 1,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateStationDialog(StateSetter setDialogState, List<route_models.RouteStation> routeStations) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    
    int? selectedCityId = _cities.isNotEmpty ? _cities.first.id : null;
    int? selectedZoneId = _zones.isNotEmpty ? _zones.first.id : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerState) => AlertDialog(
          title: const Text('Dodaj novo stajalište'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Naziv stajališta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCityId,
                    decoration: const InputDecoration(
                      labelText: 'Grad',
                      border: OutlineInputBorder(),
                    ),
                    items: _cities.map((city) {
                      return DropdownMenuItem<int>(
                        value: city.id,
                        child: Text(city.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setInnerState(() {
                        selectedCityId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedZoneId,
                    decoration: const InputDecoration(
                      labelText: 'Zona',
                      border: OutlineInputBorder(),
                    ),
                    items: _zones.map((zone) {
                      return DropdownMenuItem<int>(
                        value: zone.id,
                        child: Text(zone.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setInnerState(() {
                        selectedZoneId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    selectedCityId == null ||
                    selectedZoneId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Molimo popunite sva obavezna polja')),
                  );
                  return;
                }

                try {
                  final createRequest = CreateStationRequest(
                    name: nameController.text,
                    address: addressController.text.isEmpty ? null : addressController.text,
                    latitude: latitudeController.text.isEmpty
                        ? null
                        : double.tryParse(latitudeController.text),
                    longitude: longitudeController.text.isEmpty
                        ? null
                        : double.tryParse(longitudeController.text),
                    cityId: selectedCityId!,
                    zoneId: selectedZoneId!,
                  );
                  
                  final newStation = await _stationService.create(createRequest);
                  
                  setDialogState(() {
                    if (!_stations.any((s) => s.id == newStation.id)) {
                      _stations.add(newStation);
                    }
                    routeStations.add(route_models.RouteStation(
                      stationId: newStation.id,
                      stationName: newStation.name,
                      stationAddress: newStation.address,
                      order: routeStations.length + 1,
                    ));
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stajalište je uspješno dodato')),
                    );
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
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }
}
