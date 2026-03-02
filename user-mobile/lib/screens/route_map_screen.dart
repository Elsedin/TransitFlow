import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/transport_line_model.dart' as models;

class RouteMapScreen extends StatelessWidget {
  final models.Route route;

  const RouteMapScreen({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final stationsWithCoords = route.stations
        .where((s) => s.latitude != null && s.longitude != null)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (stationsWithCoords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${route.transportLineNumber} - Karta'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Koordinate stanica nisu dostupne'),
        ),
      );
    }

    final sortedStations = stationsWithCoords.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final lats = sortedStations.map((s) => s.latitude!).toList();
    final lons = sortedStations.map((s) => s.longitude!).toList();

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLon = lons.reduce((a, b) => a < b ? a : b);
    final maxLon = lons.reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    double initialZoom = 13.0;
    if (maxDiff < 0.01) {
      initialZoom = 15.0;
    } else if (maxDiff < 0.05) {
      initialZoom = 13.0;
    } else if (maxDiff < 0.1) {
      initialZoom = 11.0;
    } else {
      initialZoom = 10.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${route.transportLineNumber} - Karta'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(centerLat, centerLon),
          initialZoom: initialZoom,
          minZoom: 5.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.transitflow_user',
            maxZoom: 19,
          ),
          if (sortedStations.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: sortedStations
                      .map((s) => LatLng(s.latitude!, s.longitude!))
                      .toList(),
                  strokeWidth: 4.0,
                  color: Colors.orange[700]!,
                ),
              ],
            ),
          MarkerLayer(
            markers: sortedStations.asMap().entries.map((entry) {
              final index = entry.key;
              final station = entry.value;
              final isFirst = index == 0;
              final isLast = index == sortedStations.length - 1;

              return Marker(
                point: LatLng(station.latitude!, station.longitude!),
                width: 80,
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFirst
                            ? Colors.green
                            : isLast
                                ? Colors.red
                                : Colors.orange[700],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        isFirst
                            ? Icons.play_arrow
                            : isLast
                                ? Icons.stop
                                : Icons.circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        station.stationName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${route.transportLineNumber}: ${route.origin} → ${route.destination}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${sortedStations.length} stanica',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
