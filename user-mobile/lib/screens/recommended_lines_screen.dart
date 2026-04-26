import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../services/transport_line_service.dart';
import '../models/transport_line_model.dart' as models;
import 'line_details_screen.dart';

class RecommendedLinesScreen extends StatefulWidget {
  const RecommendedLinesScreen({super.key});

  @override
  State<RecommendedLinesScreen> createState() => _RecommendedLinesScreenState();
}

class _RecommendedLinesScreenState extends State<RecommendedLinesScreen> {
  final _recommendationService = RecommendationService();
  final _transportLineService = TransportLineService();
  List<models.RecommendedLine> _recommendedLines = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool?> _feedbackStatus = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendedLines();
  }

  Future<void> _loadRecommendedLines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lines = await _recommendationService.getRecommendedLines(count: 50);
      final feedbackMap = <int, bool?>{};
      for (final recommendedLine in lines) {
        if (recommendedLine.hasPositiveFeedback == true) {
          feedbackMap[recommendedLine.id] = true;
        } else if (recommendedLine.hasNegativeFeedback == true) {
          feedbackMap[recommendedLine.id] = false;
        } else {
          feedbackMap[recommendedLine.id] = null;
        }
      }
      
      setState(() {
        _recommendedLines = lines;
        _feedbackStatus.clear();
        _feedbackStatus.addAll(feedbackMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<int?> _getRouteDuration(models.TransportLine line) async {
    try {
      final route = await _transportLineService.getRouteByLineId(line.id);
      return route?.estimatedDurationMinutes;
    } catch (e) {
      return null;
    }
  }

  void _showExplanationDialog(String explanation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Objašnjenje preporuke',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          content: Text(
            explanation,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
  }

  void _showSystemExplanationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Kako funkcioniše sistem preporuke?',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sistem analizira vaša prethodna putovanja, kupljene karte i omiljene linije. Na osnovu sličnosti sa drugim korisnicima, preporučuje linije koje bi mogle biti od interesa. Preporuke se automatski ažuriraju kada kupite kartu, dodate omiljenu liniju ili ocijenite preporuku.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kako se računa skor:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Kupovina karte: +1.0 po karti\n• Dodavanje u omiljene: +5.0\n• Pozitivan feedback: +10.0\n• Slični korisnici: skor se množi sa sličnošću',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Linije su sortirane po skoru - prva linija ima najveći skor.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Preporučene linije'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
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
                        onPressed: _loadRecommendedLines,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showSystemExplanationDialog();
                          },
                          icon: Icon(Icons.info_outline, color: Colors.blue[700]),
                          label: const Text('Kako funkcioniše sistem preporuke?'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[300]!),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      if (_recommendedLines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Trenutno nema preporučenih linija.\nKupite karte ili dodajte omiljene linije da biste dobili personalizovane preporuke.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preporučeno za vas (${_recommendedLines.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._recommendedLines.asMap().entries.map((entry) {
                                final index = entry.key;
                                final recommendedLine = entry.value;
                                final line = recommendedLine.toTransportLine();
                                return FutureBuilder<int?>(
                                  future: _getRouteDuration(line),
                                  builder: (context, snapshot) {
                                    final duration = snapshot.data ?? 0;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < _recommendedLines.length - 1 ? 12 : 0,
                                      ),
                                      child: _buildLineCard(recommendedLine, line, duration, index + 1),
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

  Widget _buildLineCard(models.RecommendedLine recommendedLine, models.TransportLine line, int estimatedTime, int position) {
    return Card(
      margin: EdgeInsets.zero,
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
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: position == 1 
                                  ? Colors.amber[700]
                                  : position == 2
                                      ? Colors.grey[400]
                                      : Colors.brown[300],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$position',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            line.lineNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${line.origin} → ${line.destination}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (recommendedLine.scoreExplanation != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            _showExplanationDialog(recommendedLine.scoreExplanation!);
                          },
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      _getTransportIcon(line.transportTypeName),
                      color: Colors.orange[700],
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Skor: ${recommendedLine.score.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
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
                  child: IconButton(
                    icon: Icon(
                      _feedbackStatus[line.id] == true 
                          ? Icons.thumb_up 
                          : Icons.thumb_up_outlined, 
                      size: 20
                    ),
                    color: _feedbackStatus[line.id] == true 
                        ? Colors.green 
                        : Colors.grey[600],
                    onPressed: () async {
                      final currentStatus = _feedbackStatus[line.id];
                      final wasAlreadyActive = currentStatus == true;
                      
                      try {
                        await _recommendationService.sendFeedback(line.id, true);
                        final updatedFeedbackStatus = await _recommendationService.getFeedbackStatus(line.id);
                        if (mounted) {
                          setState(() {
                            _feedbackStatus[line.id] = updatedFeedbackStatus;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasAlreadyActive 
                                  ? 'Ocjena je uklonjena.' 
                                  : 'Hvala! Preporuka je sačuvana.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _loadRecommendedLines();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(
                      _feedbackStatus[line.id] == false 
                          ? Icons.thumb_down 
                          : Icons.thumb_down_outlined, 
                      size: 20
                    ),
                    color: _feedbackStatus[line.id] == false 
                        ? Colors.red 
                        : Colors.grey[600],
                    onPressed: () async {
                      final currentStatus = _feedbackStatus[line.id];
                      final wasAlreadyActive = currentStatus == false;
                      
                      try {
                        await _recommendationService.sendFeedback(line.id, false);
                        final updatedFeedbackStatus = await _recommendationService.getFeedbackStatus(line.id);
                        if (mounted) {
                          setState(() {
                            _feedbackStatus[line.id] = updatedFeedbackStatus;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasAlreadyActive 
                                  ? 'Ocjena je uklonjena.' 
                                  : 'Preporuka je uklonjena.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _loadRecommendedLines();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
