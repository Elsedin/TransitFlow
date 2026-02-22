import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transport_line_service.dart';
import '../models/transport_line_model.dart' as models;

class LineDetailsScreen extends StatefulWidget {
  final int lineId;

  const LineDetailsScreen({super.key, required this.lineId});

  @override
  State<LineDetailsScreen> createState() => _LineDetailsScreenState();
}

class _LineDetailsScreenState extends State<LineDetailsScreen> {
  final _transportLineService = TransportLineService();
  models.TransportLine? _line;
  models.Route? _route;
  List<models.Schedule> _schedules = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadLineDetails();
  }

  Future<void> _loadLineDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final line = await _transportLineService.getById(widget.lineId);
      if (line == null) {
        setState(() {
          _errorMessage = 'Linija nije pronađena';
          _isLoading = false;
        });
        return;
      }

      final route = await _transportLineService.getRouteByLineId(line.id);
      final schedules = route != null
          ? await _transportLineService.getSchedulesByRouteId(route.id)
          : <models.Schedule>[];

      final todaySchedules = _filterTodaySchedules(schedules);

      setState(() {
        _line = line;
        _route = route;
        _schedules = todaySchedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<models.Schedule> _filterTodaySchedules(List<models.Schedule> schedules) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday % 7;
    final currentTime = TimeOfDay.fromDateTime(now);

    final todaySchedules = schedules
        .where((s) => s.dayOfWeek == currentDayOfWeek)
        .where((s) {
          final departure = _parseTime(s.departureTime);
          final departureMinutes = departure.hour * 60 + departure.minute;
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          return departureMinutes >= currentMinutes;
        })
        .toList();

    todaySchedules.sort((a, b) {
      final aTime = _parseTime(a.departureTime);
      final bTime = _parseTime(b.departureTime);
      final aMinutes = aTime.hour * 60 + aTime.minute;
      final bMinutes = bTime.hour * 60 + bTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return todaySchedules.take(3).toList();
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeUntil(TimeOfDay departure) {
    final now = DateTime.now();
    var departureDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      departure.hour,
      departure.minute,
    );

    if (departureDateTime.isBefore(now)) {
      departureDateTime = departureDateTime.add(const Duration(days: 1));
    }

    final difference = departureDateTime.difference(now);
    final minutes = difference.inMinutes;

    if (minutes < 60) {
      return 'Za $minutes minuta';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return 'Za $hours h $remainingMinutes min';
    }
  }

  String _calculateArrival(String departureTime, int durationMinutes) {
    final parts = departureTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final departure = DateTime(2024, 1, 1, hour, minute);
    final arrival = departure.add(Duration(minutes: durationMinutes));

    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
  }

  IconData _getTransportIcon(String transportType) {
    switch (transportType.toLowerCase()) {
      case 'autobus':
        return Icons.directions_bus;
      case 'tramvaj':
        return Icons.tram;
      case 'trolejbus':
        return Icons.electric_bolt;
      default:
        return Icons.directions_bus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_line?.lineNumber ?? 'Linija'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLineDetails,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_line != null && _route != null) ...[
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.orange[400]!,
                                Colors.orange[600]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getTransportIcon(_line!.transportTypeName),
                                size: 60,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_route!.origin} → ${_route!.destination}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_line!.transportTypeName} • ${_route!.estimatedDurationMinutes} minuta',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sljedeći polasci',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_schedules.isEmpty)
                                const Text('Nema polazaka za danas')
                              else
                                ..._schedules.map((schedule) {
                                  final departure = _parseTime(schedule.departureTime);
                                  final arrivalTime = _calculateArrival(
                                    schedule.departureTime,
                                    _route!.estimatedDurationMinutes,
                                  );
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                schedule.departureTime,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatTimeUntil(departure),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Stajalište: ${_route!.origin}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Dolazak: $arrivalTime',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stajališta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_route!.stations.isEmpty)
                                const Text('Nema stajališta')
                              else
                                ..._route!.stations.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final station = entry.value;
                                  final isFirst = index == 0;
                                  final isLast = index == _route!.stations.length - 1;
                                  final estimatedTime = (index * _route!.estimatedDurationMinutes / _route!.stations.length).round();

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.orange[700],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (!isLast)
                                            Container(
                                              width: 2,
                                              height: 40,
                                              color: Colors.orange[700],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                station.stationName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (isFirst)
                                                Text(
                                                  'Početna stanica',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                )
                                              else if (isLast)
                                                Text(
                                                  'Krajnja stanica • ~${_route!.estimatedDurationMinutes} min',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                )
                                              else
                                                Text(
                                                  '~$estimatedTime min',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cijene karata',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      _buildPriceRow('Pojedinačna', '1.80 KM'),
                                      const Divider(),
                                      _buildPriceRow('Dnevna', '3.50 KM'),
                                      const Divider(),
                                      _buildPriceRow('Mjesečna', '45.00 KM'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Navigate to ticket purchase
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Kupi kartu'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Show ticket
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Prikaži kartu'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
