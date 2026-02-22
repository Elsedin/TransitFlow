import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/transport_line_service.dart';
import '../models/transport_line_model.dart' as models;
import 'profile_screen.dart';
import 'line_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();

  final List<Widget> _screens = [
    const _HomeTab(),
    const _LinesTab(),
    const _TicketsTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Početna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Linije',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Karte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _transportLineService = TransportLineService();
  List<models.TransportLine> _allLines = [];
  List<models.TransportLine> _recommendedLines = [];
  List<models.TransportLine> _favoriteLines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    try {
      final lines = await _transportLineService.getAll(isActive: true);
      setState(() {
        _allLines = lines;
        _recommendedLines = lines.take(3).toList();
        _favoriteLines = lines.take(2).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getNextDeparture(models.TransportLine line) async {
    try {
      final route = await _transportLineService.getRouteByLineId(line.id);
      if (route == null) return null;

      final schedules = await _transportLineService.getSchedulesByRouteId(route.id);
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday % 7;
      final currentTime = TimeOfDay.fromDateTime(now);

      final todaySchedules = schedules
          .where((s) => s.dayOfWeek == currentDayOfWeek)
          .where((s) {
            final parts = s.departureTime.split(':');
            final departure = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
            final departureMinutes = departure.hour * 60 + departure.minute;
            final currentMinutes = currentTime.hour * 60 + currentTime.minute;
            return departureMinutes >= currentMinutes;
          })
          .toList();

      if (todaySchedules.isEmpty) return null;
      todaySchedules.sort((a, b) {
        final aTime = _parseTime(a.departureTime);
        final bTime = _parseTime(b.departureTime);
        final aMinutes = aTime.hour * 60 + aTime.minute;
        final bMinutes = bTime.hour * 60 + bTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

      return todaySchedules.first.departureTime;
    } catch (e) {
      return null;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<int?> _getRouteDuration(models.TransportLine line) async {
    try {
      final route = await _transportLineService.getRouteByLineId(line.id);
      return route?.estimatedDurationMinutes;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_bus, color: Colors.white),
            const SizedBox(width: 8),
            const Text('TransitFlow'),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Kupi kartu',
                      Icons.confirmation_number,
                      Colors.orange[700]!,
                      Colors.white,
                      () {
                        // TODO: Navigate to ticket purchase
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'Moje karte',
                      Icons.assignment,
                      Colors.white,
                      Colors.orange[700]!,
                      () {
                        // TODO: Navigate to tickets
                      },
                      borderColor: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Pretraži liniju ili stajalište...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Preporučeno za vas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Vidi sve'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recommendedLines.isEmpty
                      ? const Center(child: Text('Nema preporučenih linija'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recommendedLines.length,
                          itemBuilder: (context, index) {
                            final line = _recommendedLines[index];
                            return FutureBuilder<String?>(
                              future: _getNextDeparture(line),
                              builder: (context, snapshot) {
                                final nextDeparture = snapshot.data ?? 'N/A';
                                return Padding(
                                  padding: EdgeInsets.only(right: index < _recommendedLines.length - 1 ? 12 : 0),
                                  child: _buildRecommendedLineCard(
                                    line.lineNumber,
                                    '${line.origin} → ${line.destination}',
                                    nextDeparture,
                                    line.id,
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Omiljene linije',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Vidi sve'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favoriteLines.isEmpty
                      ? const Center(child: Text('Nema omiljenih linija'))
                      : Column(
                          children: [
                            ..._favoriteLines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final line = entry.value;
                              return FutureBuilder<int?>(
                                future: _getRouteDuration(line),
                                builder: (context, snapshot) {
                                  final duration = snapshot.data ?? 0;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: index < _favoriteLines.length - 1 ? 12 : 0),
                                    child: _buildFavoriteLineCard(
                                      line.lineNumber,
                                      '${line.origin} → ${line.destination}',
                                      '$duration min',
                                      '1.80 KM',
                                      line.id,
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color backgroundColor, Color iconColor, VoidCallback onTap, {Color? borderColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedLineCard(String lineNumber, String route, String nextDeparture, int lineId) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lineNumber,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Preporučeno',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            route,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sljedeći polazak: $nextDeparture',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LineDetailsScreen(lineId: lineId),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Prikaži detalje'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteLineCard(String lineNumber, String route, String duration, String price, int lineId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lineNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Vrijeme vožnje: $duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Cijena: $price',
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
              IconButton(
                icon: Icon(Icons.star, color: Colors.orange[700]),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LineDetailsScreen(lineId: lineId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kupi kartu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesTab extends StatefulWidget {
  const _LinesTab();

  @override
  State<_LinesTab> createState() => _LinesTabState();
}

class _LinesTabState extends State<_LinesTab> {
  final _transportLineService = TransportLineService();
  List<models.TransportLine> _lines = [];
  List<models.TransportLine> _filteredLines = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lines = await _transportLineService.getAll(isActive: true);
      setState(() {
        _lines = lines;
        _filteredLines = lines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredLines = _lines.where((line) {
        final matchesSearch = _searchController.text.isEmpty ||
            line.lineNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            line.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            line.origin.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            line.destination.toLowerCase().contains(_searchController.text.toLowerCase());

        final matchesFilter = _selectedFilter == null ||
            _selectedFilter == 'Sve' ||
            line.transportTypeName.toLowerCase() == _selectedFilter!.toLowerCase();

        return matchesSearch && matchesFilter;
      }).toList();
    });
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
        title: const Text('Linije'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality is in the body
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži liniju...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Sve', _selectedFilter == null || _selectedFilter == 'Sve'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Autobus', _selectedFilter == 'Autobus'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tramvaj', _selectedFilter == 'Tramvaj'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Trolejbus', _selectedFilter == 'Trolejbus'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
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
                              onPressed: _loadLines,
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      )
                    : _filteredLines.isEmpty
                        ? const Center(
                            child: Text('Nema pronađenih linija'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredLines.length,
                            itemBuilder: (context, index) {
                              final line = _filteredLines[index];
                              return FutureBuilder<int?>(
                                future: _getRouteDuration(line),
                                builder: (context, snapshot) {
                                  final duration = snapshot.data ?? 0;
                                  return _buildLineCard(line, duration);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? label : null;
        });
        _applyFilters();
      },
      selectedColor: Colors.orange[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Future<int?> _getRouteDuration(models.TransportLine line) async {
    try {
      final route = await _transportLineService.getRouteByLineId(line.id);
      return route?.estimatedDurationMinutes;
    } catch (e) {
      return null;
    }
  }

  Widget _buildLineCard(models.TransportLine line, int estimatedTime) {
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.lineNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${line.origin} → ${line.destination}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getTransportIcon(line.transportTypeName),
                  color: Colors.orange[700],
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    line.transportTypeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  estimatedTime > 0 ? 'Vrijeme: $estimatedTime min' : 'Vrijeme: N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LineDetailsScreen(lineId: line.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Detalji'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Show map
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Karta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _TicketsTab extends StatelessWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje karte'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Karte - U izradi'),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
