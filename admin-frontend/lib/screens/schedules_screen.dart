import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/route_service.dart';
import '../services/vehicle_service.dart';
import '../models/schedule_model.dart';
import '../models/route_model.dart' as route_models;
import '../models/vehicle_model.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _scheduleService = ScheduleService();
  final _routeService = RouteService();
  final _vehicleService = VehicleService();
  List<Schedule> _schedules = [];
  List<Schedule> _filteredSchedules = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _routeFilter;
  int? _vehicleFilter;
  int? _dayOfWeekFilter;
  bool? _statusFilter;
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schedules = await _scheduleService.getAll(
        routeId: _routeFilter,
        vehicleId: _vehicleFilter,
        dayOfWeek: _dayOfWeekFilter,
        isActive: _statusFilter,
      );
      setState(() {
        _schedules = schedules;
        _filteredSchedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load schedules: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSchedules = _schedules.where((schedule) {
        if (_routeFilter != null && schedule.routeId != _routeFilter) {
          return false;
        }
        if (_vehicleFilter != null && schedule.vehicleId != _vehicleFilter) {
          return false;
        }
        if (_dayOfWeekFilter != null && schedule.dayOfWeek != _dayOfWeekFilter) {
          return false;
        }
        if (_statusFilter != null && schedule.isActive != _statusFilter) {
          return false;
        }
        return true;
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši raspored'),
        content: const Text('Da li ste sigurni da želite obrisati ovaj raspored?'),
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
        final success = await _scheduleService.delete(id);
        if (success) {
          _loadSchedules();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Raspored uspješno obrisan')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Neuspješno brisanje rasporeda')),
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

  Future<void> _showAddEditDialog({Schedule? schedule}) async {
    await showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        schedule: schedule,
        onSave: () {
          _loadSchedules();
        },
      ),
    );
  }

  List<Schedule> get _paginatedSchedules {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredSchedules.length);
    return _filteredSchedules.sublist(start, end);
  }

  int get _totalPages => (_filteredSchedules.length / _itemsPerPage).ceil();

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
                'Upravljanje rasporedom',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj novi raspored'),
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
            'Svi rasporedi',
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
                  child: FutureBuilder<List<route_models.Route>>(
                    future: _routeService.getAll(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: [],
                            hint: const Text('Učitavanje ruta...'),
                            onChanged: null,
                          ),
                        );
                      }
                      final routes = snapshot.data!;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _routeFilter,
                          hint: const Text('Sve rute'),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Sve rute')),
                            ...routes.map((route) => DropdownMenuItem<int?>(
                                  value: route.id,
                                  child: Text(route.name),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _routeFilter = value;
                            });
                            _loadSchedules();
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
                  child: FutureBuilder<List<Vehicle>>(
                    future: _vehicleService.getAll(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: [],
                            hint: const Text('Učitavanje vozila...'),
                            onChanged: null,
                          ),
                        );
                      }
                      final vehicles = snapshot.data!;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _vehicleFilter,
                          hint: const Text('Sva vozila'),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Sva vozila')),
                            ...vehicles.map((vehicle) => DropdownMenuItem<int?>(
                                  value: vehicle.id,
                                  child: Text(vehicle.licensePlate),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _vehicleFilter = value;
                            });
                            _loadSchedules();
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
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _dayOfWeekFilter,
                      hint: const Text('Svi dani'),
                      icon: const Icon(Icons.filter_list),
                      items: const [
                        DropdownMenuItem<int?>(value: null, child: Text('Svi dani')),
                        DropdownMenuItem<int?>(value: 1, child: Text('Ponedjeljak')),
                        DropdownMenuItem<int?>(value: 2, child: Text('Utorak')),
                        DropdownMenuItem<int?>(value: 3, child: Text('Srijeda')),
                        DropdownMenuItem<int?>(value: 4, child: Text('Četvrtak')),
                        DropdownMenuItem<int?>(value: 5, child: Text('Petak')),
                        DropdownMenuItem<int?>(value: 6, child: Text('Subota')),
                        DropdownMenuItem<int?>(value: 0, child: Text('Nedjelja')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _dayOfWeekFilter = value;
                        });
                        _loadSchedules();
                      },
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
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
                    hint: const Text('Svi rasporedi'),
                    icon: const Icon(Icons.filter_list),
                    items: const [
                      DropdownMenuItem<bool?>(value: null, child: Text('Svi rasporedi')),
                      DropdownMenuItem<bool?>(value: true, child: Text('Aktivni')),
                      DropdownMenuItem<bool?>(value: false, child: Text('Neaktivni')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                      _loadSchedules();
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
    if (_paginatedSchedules.isEmpty) {
      return const Center(child: Text('Nema pronađenih rasporeda'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(1.2),
          3: FlexColumnWidth(1.0),
          4: FlexColumnWidth(1.0),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.3),
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
              _TableHeaderCell('Ruta'),
              _TableHeaderCell('Vozilo'),
              _TableHeaderCell('Vrijeme polaska'),
              _TableHeaderCell('Vrijeme dolaska'),
              _TableHeaderCell('Dan u nedjelji'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedSchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(schedule.id.toString()),
                _TableCell(schedule.routeName),
                _TableCell(schedule.vehicleLicensePlate),
                _TableCell(schedule.departureTime),
                _TableCell(schedule.arrivalTime),
                _TableCell(schedule.dayOfWeekName),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        schedule.isActive ? 'Aktivno' : 'Neaktivno',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: schedule.isActive ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _TableCell(
                  '',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showAddEditDialog(schedule: schedule),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Uredi'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _deleteSchedule(schedule.id),
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
            'Prikazano ${_paginatedSchedules.length} od ${_filteredSchedules.length} rasporeda',
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

class _ScheduleDialog extends StatefulWidget {
  final Schedule? schedule;
  final VoidCallback onSave;

  const _ScheduleDialog({
    this.schedule,
    required this.onSave,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleService = ScheduleService();
  final _routeService = RouteService();
  final _vehicleService = VehicleService();
  int? _selectedRouteId;
  int? _selectedVehicleId;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
  int? _selectedDayOfWeek;
  bool _isActive = true;
  bool _isLoading = false;
  List<route_models.Route> _routes = [];
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedRouteId = widget.schedule!.routeId;
      _selectedVehicleId = widget.schedule!.vehicleId;
      final depParts = widget.schedule!.departureTime.split(':');
      _departureTime = TimeOfDay(
        hour: int.parse(depParts[0]),
        minute: int.parse(depParts[1]),
      );
      final arrParts = widget.schedule!.arrivalTime.split(':');
      _arrivalTime = TimeOfDay(
        hour: int.parse(arrParts[0]),
        minute: int.parse(arrParts[1]),
      );
      _selectedDayOfWeek = widget.schedule!.dayOfWeek;
      _isActive = widget.schedule!.isActive;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final routes = await _routeService.getAll();
      final vehicles = await _vehicleService.getAll();
      setState(() {
        _routes = routes;
        _vehicles = vehicles;
        if (widget.schedule == null && _routes.isNotEmpty && _selectedRouteId == null) {
          _selectedRouteId = _routes.first.id;
        }
        if (widget.schedule == null && _vehicles.isNotEmpty && _selectedVehicleId == null) {
          _selectedVehicleId = _vehicles.first.id;
        }
        if (_selectedDayOfWeek == null) {
          _selectedDayOfWeek = 1;
        }
        if (_departureTime == null) {
          _departureTime = const TimeOfDay(hour: 8, minute: 0);
        }
        if (_arrivalTime == null) {
          _arrivalTime = const TimeOfDay(hour: 9, minute: 0);
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

  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? (_departureTime ?? const TimeOfDay(hour: 8, minute: 0)) : (_arrivalTime ?? const TimeOfDay(hour: 9, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureTime = picked;
        } else {
          _arrivalTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRouteId == null || _selectedVehicleId == null || _departureTime == null || _arrivalTime == null || _selectedDayOfWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva polja')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final departureTimeStr = '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}';
      final arrivalTimeStr = '${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}';

      if (widget.schedule == null) {
        await _scheduleService.create(CreateScheduleRequest(
          routeId: _selectedRouteId!,
          vehicleId: _selectedVehicleId!,
          departureTime: departureTimeStr,
          arrivalTime: arrivalTimeStr,
          dayOfWeek: _selectedDayOfWeek!,
        ));
      } else {
        await _scheduleService.update(widget.schedule!.id, UpdateScheduleRequest(
          routeId: _selectedRouteId!,
          vehicleId: _selectedVehicleId!,
          departureTime: departureTimeStr,
          arrivalTime: arrivalTimeStr,
          dayOfWeek: _selectedDayOfWeek!,
          isActive: _isActive,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.schedule == null
                ? 'Raspored je uspješno dodat'
                : 'Raspored je uspješno ažuriran'),
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
      title: Text(widget.schedule == null ? 'Dodaj novi raspored' : 'Uredi raspored'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedRouteId,
                  decoration: const InputDecoration(
                    labelText: 'Ruta',
                    border: OutlineInputBorder(),
                  ),
                  items: _routes.map((route) => DropdownMenuItem<int>(
                        value: route.id,
                        child: Text(route.name),
                      )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRouteId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite rutu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Vozilo',
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicles.map((vehicle) => DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(vehicle.licensePlate),
                      )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite vozilo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Vrijeme polaska',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _departureTime != null
                                ? '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}'
                                : 'Odaberite vrijeme',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Vrijeme dolaska',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(
                            _arrivalTime != null
                                ? '${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
                                : 'Odaberite vrijeme',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedDayOfWeek,
                  decoration: const InputDecoration(
                    labelText: 'Dan u nedjelji',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<int>(value: 1, child: Text('Ponedjeljak')),
                    DropdownMenuItem<int>(value: 2, child: Text('Utorak')),
                    DropdownMenuItem<int>(value: 3, child: Text('Srijeda')),
                    DropdownMenuItem<int>(value: 4, child: Text('Četvrtak')),
                    DropdownMenuItem<int>(value: 5, child: Text('Petak')),
                    DropdownMenuItem<int>(value: 6, child: Text('Subota')),
                    DropdownMenuItem<int>(value: 0, child: Text('Nedjelja')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDayOfWeek = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Molimo odaberite dan u nedjelji';
                    }
                    return null;
                  },
                ),
                if (widget.schedule != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Aktivan'),
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
