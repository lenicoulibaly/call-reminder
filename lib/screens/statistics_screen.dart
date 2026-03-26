import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../models/contact_circle.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  List<ContactCircle> _circles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _stats = DatabaseService.getStatistics();
      _circles = DatabaseService.getAllCircles();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalDuration = _stats!['totalDurationSeconds'] as int;
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartes de statistiques générales
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Contacts',
                      _stats!['totalContacts'].toString(),
                      Icons.people,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Appels',
                      _stats!['totalCalls'].toString(),
                      Icons.phone,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Cercles',
                      _stats!['totalCircles'].toString(),
                      Icons.group_work,
                      const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Durée totale',
                      '$hours h $minutes min',
                      Icons.timer,
                      const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Graphique des appels par cercle
              if (_stats!['callsByCircle'] != null &&
                  (_stats!['callsByCircle'] as Map).isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Répartition des appels par cercle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieChartSections(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLegend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Contact le plus appelé
              if (_stats!['mostCalledContactId'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Contact le plus appelé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMostCalledContact(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final callsByCircle = _stats!['callsByCircle'] as Map<String, int>;
    final total = callsByCircle.values.fold<int>(0, (sum, count) => sum + count);

    return callsByCircle.entries.map((entry) {
      final circle = _circles.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => _circles.first,
      );
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: Color(int.parse(circle.colorHex)),
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final callsByCircle = _stats!['callsByCircle'] as Map<String, int>;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: callsByCircle.entries.map((entry) {
        final circle = _circles.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => _circles.first,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(int.parse(circle.colorHex)),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${circle.name}: ${entry.value}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMostCalledContact() {
    final contactId = _stats!['mostCalledContactId'] as String;
    final callCount = _stats!['mostCalledCount'] as int;
    
    final contact = DatabaseService.getAllContacts()
        .firstWhere((c) => c.id == contactId);
    
    final circle = _circles.firstWhere((c) => c.id == contact.circleId);

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(int.parse(circle.colorHex))
              .withValues(alpha: 0.2),
          child: Text(
            contact.name[0].toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              color: Color(int.parse(circle.colorHex)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$callCount appel(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
