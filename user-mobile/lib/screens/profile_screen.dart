import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/ticket_service.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import 'login_screen.dart';
import 'subscriptions_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _authService = AuthService();
  final _ticketService = TicketService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;
  int _totalTickets = 0;
  int _totalTrips = 0;
  int _favoriteLines = 0;
  double _totalSpent = 0.0;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _editSectionKey = GlobalKey();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userService.getCurrentUser();
      final tickets = await _ticketService.getAll();
      
      final totalTickets = tickets.length;
      final totalTrips = tickets.where((t) => t.isUsed).length;
      final favoriteLines = tickets
          .where((t) => t.routeId != null)
          .map((t) => t.routeId)
          .toSet()
          .length;
      final totalSpent = tickets.fold<double>(0.0, (sum, ticket) => sum + ticket.price);

      setState(() {
        _user = user;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _phoneNumberController.text = user.phoneNumber ?? '';
        _totalTickets = totalTickets;
        _totalTrips = totalTrips;
        _favoriteLines = favoriteLines;
        _totalSpent = totalSpent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = UpdateUserProfileRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
      );

      final updatedUser = await _userService.updateProfile(request);
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil je uspješno ažuriran')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da želite da se odjavite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O aplikaciji'),
        content: const Text(
          'TransitFlow\n\nAplikacija za javni prevoz koja omogućava jednostavnu kupovinu karata i upravljanje putovanjima.\n\nVerzija: 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomoć'),
        content: const SingleChildScrollView(
          child: Text(
            'Kako koristiti aplikaciju:\n\n'
            '• Kupovina karata: Odaberite liniju, datum, vrijeme i tip karte\n'
            '• Moje karte: Pregledajte sve kupljene karte sa QR kodovima\n'
            '• Profil: Uredite lične podatke i pregledajte statistiku\n'
            '• Linije: Pretražite i odaberite linije javnog prevoza\n\n'
            'Za dodatnu pomoć kontaktirajte podršku.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'about') {
                _showAboutDialog();
              } else if (value == 'help') {
                _showHelpDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('O aplikaciji'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Pomoć'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Odjavi se', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _user == null
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
                        onPressed: _loadUser,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user?.fullName.isNotEmpty == true ? _user!.fullName : _user?.username ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                  });
                                  if (_isEditing) {
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (_editSectionKey.currentContext != null) {
                                        Scrollable.ensureVisible(
                                          _editSectionKey.currentContext!,
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                          alignment: 0.1,
                                        );
                                      }
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.orange[700],
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Uredi Profil'),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(_totalTickets.toString(), 'Kupljenih karata'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(_totalTrips.toString(), 'Putovanja'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(_favoriteLines.toString(), 'Omiljene linije'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Statistika',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPersonalDataRow('Ukupno potrošeno', '${_totalSpent.toStringAsFixed(2)} KM'),
                                  const Divider(),
                                  _buildPersonalDataRow('Prosječna cijena karte', _totalTickets > 0 ? '${(_totalSpent / _totalTickets).toStringAsFixed(2)} KM' : '0.00 KM'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SubscriptionsListScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.card_membership, color: Colors.orange[700], size: 32),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pretplate',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Kupite ili obnovite pretplatu',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lični podaci',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPersonalDataRow('Ime i prezime', _user?.fullName.isNotEmpty == true ? _user!.fullName : _user?.username ?? ''),
                                  const Divider(),
                                  _buildPersonalDataRow('Email', _user?.email ?? ''),
                                  const Divider(),
                                  _buildPersonalDataRow('Telefon', _user?.phoneNumber ?? 'Nije uneseno'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          Padding(
                            key: _editSectionKey,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Ime',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Prezime',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Molimo unesite email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Molimo unesite validan email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Telefon',
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Sačuvaj promjene', style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_errorMessage != null && _isEditing) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
