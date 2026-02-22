import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.orange[700], size: 32),
                const SizedBox(width: 12),
                const Text(
                  'TransitFlow Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionTitle('DASHBOARD'),
                _buildMenuItem(
                  'Pregled',
                  Icons.dashboard,
                  '/dashboard',
                  currentRoute == '/dashboard',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('UPRAVLJANJE'),
                _buildMenuItem(
                  'Linije',
                  Icons.route,
                  '/lines',
                  currentRoute == '/lines',
                ),
                _buildMenuItem(
                  'Rute',
                  Icons.map,
                  '/routes',
                  currentRoute == '/routes',
                ),
                _buildMenuItem(
                  'Vozila',
                  Icons.directions_bus,
                  '/vehicles',
                  currentRoute == '/vehicles',
                ),
                _buildMenuItem(
                  'Vozni red',
                  Icons.schedule,
                  '/schedule',
                  currentRoute == '/schedule',
                ),
                _buildMenuItem(
                  'Cijene',
                  Icons.attach_money,
                  '/prices',
                  currentRoute == '/prices',
                ),
                _buildMenuItem(
                  'Referentni podaci',
                  Icons.description,
                  '/reference-data',
                  currentRoute == '/reference-data',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('KORISNICI I TRANSAKCIJE'),
                _buildMenuItem(
                  'Korisnici',
                  Icons.people,
                  '/users',
                  currentRoute == '/users',
                ),
                _buildMenuItem(
                  'Karte',
                  Icons.confirmation_number,
                  '/tickets',
                  currentRoute == '/tickets',
                ),
                _buildMenuItem(
                  'Transakcije',
                  Icons.receipt_long,
                  '/transactions',
                  currentRoute == '/transactions',
                ),
                _buildMenuItem(
                  'Pretplate',
                  Icons.subscriptions,
                  '/subscriptions',
                  currentRoute == '/subscriptions',
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('IZVJEŠTAJI'),
                _buildMenuItem(
                  'Izvještaji',
                  Icons.description,
                  '/reports',
                  currentRoute == '/reports',
                ),
                _buildMenuItem(
                  'Notifikacije',
                  Icons.notifications,
                  '/notifications',
                  currentRoute == '/notifications',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    String route,
    bool isActive,
  ) {
    return InkWell(
      onTap: () => onNavigate(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.orange[700]!, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.orange[700] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.orange[700] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
