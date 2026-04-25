import 'package:flutter/material.dart';
import '../services/transport_line_service.dart';
import '../services/favorite_service.dart';
import '../services/recommendation_service.dart';
import '../services/ticket_service.dart';
import '../models/transport_line_model.dart' as models;
import '../models/ticket_model.dart';
import 'ticket_purchase_screen.dart';
import 'route_map_screen.dart';

class LineDetailsScreen extends StatefulWidget {
  final int lineId;

  const LineDetailsScreen({super.key, required this.lineId});

  @override
  State<LineDetailsScreen> createState() => _LineDetailsScreenState();
}

class _LineDetailsScreenState extends State<LineDetailsScreen> {
  final _transportLineService = TransportLineService();
  final _favoriteService = FavoriteService();
  final _recommendationService = RecommendationService();
  final _ticketService = TicketService();
  models.TransportLine? _line;
  models.Route? _route;
  List<models.NextDeparture> _nextDepartures = [];
  List<TicketType> _ticketTypes = [];
  List<TicketPrice> _ticketPrices = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;
  bool? _recommendationFeedback;
  bool _isSendingFeedback = false;

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
      final nextDepartures = route != null
          ? await _transportLineService.getNextDepartures(route.id, count: 3)
          : <models.NextDeparture>[];

      final ticketTypes = await _ticketService.getTicketTypes(isActive: true);
      final ticketPrices = await _ticketService.getTicketPrices(isActive: true);

      final isFavorite = await _favoriteService.isFavorite(line.id);
      final feedbackStatus = await _recommendationService.getFeedbackStatus(line.id);

      setState(() {
        _line = line;
        _route = route;
        _nextDepartures = nextDepartures;
        _ticketTypes = ticketTypes;
        _ticketPrices = ticketPrices;
        _isFavorite = isFavorite;
        _recommendationFeedback = feedbackStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatTimeUntilMinutes(int minutes) {
    if (minutes < 60) {
      return 'Za $minutes minuta';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return 'Za $hours h $remainingMinutes min';
  }

  List<int> get _availableZoneIds {
    return const [1, 2, 3];
  }

  TicketPrice? _findLatestPrice(int ticketTypeId, int zoneId) {
    final prices = _ticketPrices
        .where((p) => p.ticketTypeId == ticketTypeId && p.zoneId == zoneId && p.isActive)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort((a, b) => b.validFrom.compareTo(a.validFrom));
    return prices.first;
  }

  Future<void> _toggleFavorite() async {
    if (_line == null) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(_line!.id);
        setState(() {
          _isFavorite = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Linija je uklonjena iz omiljenih'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _favoriteService.addFavorite(_line!.id);
        setState(() {
          _isFavorite = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Linija je dodata u omiljene'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  Future<void> _sendFeedback(bool isUseful) async {
    if (_line == null) return;

    final wasAlreadyActive = _recommendationFeedback == isUseful;

    setState(() {
      _isSendingFeedback = true;
    });

    try {
      await _recommendationService.sendFeedback(_line!.id, isUseful);
      final updatedFeedbackStatus = await _recommendationService.getFeedbackStatus(_line!.id);
      setState(() {
        _recommendationFeedback = updatedFeedbackStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasAlreadyActive ? 'Ocjena je uklonjena.' : 'Hvala! Vaša ocjena je sačuvana.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingFeedback = false;
        });
      }
    }
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
          _isTogglingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? Colors.yellow : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Ukloni iz omiljenih' : 'Dodaj u omiljene',
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
                              if (_nextDepartures.isEmpty)
                                const Text('Nema planiranih polazaka')
                              else
                                ..._nextDepartures.map((schedule) {
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
                                                _formatTimeUntilMinutes(schedule.minutesUntilDeparture),
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
                                                schedule.dayOfWeekName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Dolazak: ${schedule.arrivalTime}',
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
                                      if (_ticketTypes.isEmpty)
                                        const Text('Cijene trenutno nisu dostupne')
                                      else
                                        ..._ticketTypes.expand((type) {
                                          final rows = <Widget>[];
                                          rows.add(_buildPriceRow(type.name, ''));
                                          for (final zoneId in _availableZoneIds) {
                                            final price = _findLatestPrice(type.id, zoneId);
                                            if (price == null) continue;
                                            rows.add(Padding(
                                              padding: const EdgeInsets.only(left: 12.0, top: 6, bottom: 6),
                                              child: _buildPriceRow(
                                                'Zona $zoneId',
                                                '${price.price.toStringAsFixed(2)} KM',
                                                isSubRow: true,
                                              ),
                                            ));
                                          }
                                          rows.add(const Divider());
                                          return rows;
                                        })
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
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ocijenite ovu liniju',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isSendingFeedback
                                              ? null
                                              : () => _sendFeedback(true),
                                          icon: Icon(
                                            _recommendationFeedback == true
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_outlined,
                                            color: _recommendationFeedback == true
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          label: const Text('Korisno'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _recommendationFeedback == true
                                                ? Colors.green
                                                : Colors.grey,
                                            side: BorderSide(
                                              color: _recommendationFeedback == true
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isSendingFeedback
                                              ? null
                                              : () => _sendFeedback(false),
                                          icon: Icon(
                                            _recommendationFeedback == false
                                                ? Icons.thumb_down
                                                : Icons.thumb_down_outlined,
                                            color: _recommendationFeedback == false
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          label: const Text('Nekorisno'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _recommendationFeedback == false
                                                ? Colors.red
                                                : Colors.grey,
                                            side: BorderSide(
                                              color: _recommendationFeedback == false
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TicketPurchaseScreen(
                                          lineId: _line?.id,
                                          routeId: _route?.id,
                                        ),
                                      ),
                                    );
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
                                  onPressed: _route != null
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RouteMapScreen(route: _route!),
                                            ),
                                          );
                                        }
                                      : null,
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

  Widget _buildPriceRow(String label, String price, {bool isSubRow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSubRow ? 14 : 16,
              color: isSubRow ? Colors.grey[700] : Colors.black87,
              fontWeight: isSubRow ? FontWeight.w500 : FontWeight.normal,
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
