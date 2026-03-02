import 'package:flutter/material.dart';
import '../services/favorite_service.dart';
import '../models/favorite_line_model.dart';
import 'line_details_screen.dart';

class FavoriteLinesScreen extends StatefulWidget {
  const FavoriteLinesScreen({super.key});

  @override
  State<FavoriteLinesScreen> createState() => _FavoriteLinesScreenState();
}

class _FavoriteLinesScreenState extends State<FavoriteLinesScreen> {
  final _favoriteService = FavoriteService();
  List<FavoriteLine> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await _favoriteService.getAll();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(int transportLineId) async {
    try {
      await _favoriteService.removeFavorite(transportLineId);
      if (!mounted) {
        return;
      }
      setState(() {
        _favorites.removeWhere((f) => f.transportLineId == transportLineId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Linija je uklonjena iz omiljenih'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omiljene linije'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFavorites,
                          child: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: _favorites.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nema omiljenih linija',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dodaj linije u omiljene iz detalja linije.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final favorite = _favorites[index];
                            return _buildFavoriteCard(favorite);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemCount: _favorites.length,
                        ),
                ),
    );
  }

  Widget _buildFavoriteCard(FavoriteLine favorite) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        favorite.transportLineNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${favorite.origin} → ${favorite.destination}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        favorite.transportTypeName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.star,
                    color: Colors.orange,
                  ),
                  tooltip: 'Ukloni iz omiljenih',
                  onPressed: () {
                    _removeFavorite(favorite.transportLineId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dodano: ${favorite.createdAt.day.toString().padLeft(2, '0')}.${favorite.createdAt.month.toString().padLeft(2, '0')}.${favorite.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LineDetailsScreen(lineId: favorite.transportLineId),
                      ),
                    );
                    _loadFavorites();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                  ),
                  child: const Text('Prikaži detalje'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

