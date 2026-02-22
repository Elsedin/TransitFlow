import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'transport_lines_screen.dart';
import 'routes_screen.dart';
import 'vehicles_screen.dart';
import 'schedules_screen.dart';
import 'ticket_prices_screen.dart';
import 'tickets_screen.dart';
import 'users_screen.dart';
import 'transactions_screen.dart';
import 'subscriptions_screen.dart';
import 'reports_screen.dart';
import 'reference_data_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentRoute = '/dashboard';

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentRoute) {
      case '/dashboard':
        return const DashboardScreen();
      case '/lines':
        return const TransportLinesScreen();
      case '/routes':
        return const RoutesScreen();
      case '/vehicles':
        return const VehiclesScreen();
      case '/schedule':
        return const SchedulesScreen();
      case '/prices':
        return const TicketPricesScreen();
      case '/tickets':
        return const TicketsScreen();
      case '/users':
        return const UsersScreen();
      case '/transactions':
        return const TransactionsScreen();
      case '/subscriptions':
        return const SubscriptionsScreen();
      case '/reports':
        return const ReportsScreen();
      case '/reference-data':
        return const ReferenceDataScreen();
      case '/notifications':
        return const NotificationsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentRoute: _currentRoute,
            onNavigate: _handleNavigation,
          ),
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }
}
