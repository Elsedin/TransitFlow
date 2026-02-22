import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../widgets/metric_card_enhanced.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _userService = UserService();
  UserMetrics? _metrics;
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  bool? _statusFilter;
  String? _sortBy;
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
      final metrics = await _userService.getMetrics();
      final users = await _userService.getAll(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        isActive: _statusFilter,
        sortBy: _sortBy,
      );
      setState(() {
        _metrics = metrics;
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _loadData();
  }

  Future<void> _toggleUserActive(int id, bool currentStatus) async {
    try {
      final success = await _userService.toggleActive(id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentStatus
                  ? 'Korisnik je uspješno blokiran'
                  : 'Korisnik je uspješno aktiviran'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Neuspješna promjena statusa korisnika')),
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

  Future<void> _showAddEditDialog({User? user}) async {
    await showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  Future<void> _showUserDetails(User user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalji korisnika - ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID:', user.id.toString()),
              _buildDetailRow('Korisničko ime:', user.username),
              _buildDetailRow('Email:', user.email),
              _buildDetailRow('Ime:', user.firstName ?? 'N/A'),
              _buildDetailRow('Prezime:', user.lastName ?? 'N/A'),
              _buildDetailRow('Telefon:', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Datum registracije:', DateFormat('dd.MM.yyyy').format(user.createdAt)),
              if (user.lastLoginAt != null)
                _buildDetailRow('Posljednja prijava:', DateFormat('dd.MM.yyyy HH:mm').format(user.lastLoginAt!)),
              _buildDetailRow('Broj kupovina:', user.purchaseCount.toString()),
              _buildDetailRow('Status:', user.isActive ? 'Aktivan' : 'Neaktivan'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  List<User> get _paginatedUsers {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredUsers.length);
    return _filteredUsers.sublist(start, end);
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

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
                'Upravljanje korisnicima',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži korisnike...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj korisnika'),
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
            ],
          ),
          const SizedBox(height: 24),
          if (_metrics != null) ...[
            Row(
              children: [
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'UKUPNO KORISNIKA',
                    value: _formatNumber(_metrics!.totalUsers),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'AKTIVNI KORISNICI',
                    value: _formatNumber(_metrics!.activeUsers),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'NOVI (OVAJ MJESEC)',
                    value: _formatNumber(_metrics!.newUsersThisMonth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricCardEnhanced(
                    title: 'BLOKIRANI',
                    value: _formatNumber(_metrics!.blockedUsers),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Svi korisnici',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
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
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                      child: DropdownButton<String?>(
                        value: _sortBy,
                        hint: const Text('Sortiraj po'),
                        icon: const Icon(Icons.filter_list),
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Sortiraj po')),
                          DropdownMenuItem<String?>(value: 'date', child: Text('Datumu registracije')),
                          DropdownMenuItem<String?>(value: 'name', child: Text('Imenu')),
                          DropdownMenuItem<String?>(value: 'email', child: Text('Email-u')),
                          DropdownMenuItem<String?>(value: 'purchases', child: Text('Broju kupovina')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value;
                          });
                          _applyFilters();
                        },
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    if (_paginatedUsers.isEmpty) {
      return const Center(child: Text('Nema pronađenih korisnika'));
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.8),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.0),
          6: FlexColumnWidth(1.0),
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
              _TableHeaderCell('Full Naziv'),
              _TableHeaderCell('Email'),
              _TableHeaderCell('Telefon'),
              _TableHeaderCell('Datum registracije'),
              _TableHeaderCell('Broj kupovina'),
              _TableHeaderCell('Status'),
              _TableHeaderCell('Akcije'),
            ],
          ),
          ..._paginatedUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              children: [
                _TableCell(user.id.toString()),
                _TableCell(user.fullName.isNotEmpty ? user.fullName : user.username),
                _TableCell(user.email),
                _TableCell(user.phoneNumber ?? 'N/A'),
                _TableCell(DateFormat('dd.MM.yyyy').format(user.createdAt)),
                _TableCell(user.purchaseCount.toString()),
                _TableCell(
                  '',
                  child: Center(
                    child: Chip(
                      label: Text(
                        user.isActive ? 'Aktivan' : 'Neaktivan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                      backgroundColor: user.isActive ? Colors.green : Colors.pink,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        onPressed: () => _showUserDetails(user),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Detalji'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _toggleUserActive(user.id, user.isActive),
                        style: TextButton.styleFrom(
                          foregroundColor: user.isActive ? Colors.red : Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(user.isActive ? 'Blokiraj' : 'Aktiviraj'),
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
            'Prikazano ${_paginatedUsers.length} od ${_filteredUsers.length} korisnika',
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

class _UserDialog extends StatefulWidget {
  final User? user;
  final VoidCallback onSave;

  const _UserDialog({
    this.user,
    required this.onSave,
  });

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _emailController.text = widget.user!.email;
      _firstNameController.text = widget.user!.firstName ?? '';
      _lastNameController.text = widget.user!.lastName ?? '';
      _phoneController.text = widget.user!.phoneNumber ?? '';
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.user == null) {
        await _userService.create(CreateUserRequest(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        ));
      } else {
        await _userService.update(widget.user!.id, UpdateUserRequest(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          isActive: _isActive,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.user == null
                ? 'Korisnik je uspješno dodat'
                : 'Korisnik je uspješno ažuriran'),
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
      title: Text(widget.user == null ? 'Dodaj korisnika' : 'Uredi korisnika'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Korisničko ime',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite korisničko ime';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
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
                if (widget.user == null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Lozinka',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Molimo unesite lozinku';
                      }
                      if (value.length < 6) {
                        return 'Lozinka mora imati najmanje 6 karaktera';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ime',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prezime',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                if (widget.user != null) ...[
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
