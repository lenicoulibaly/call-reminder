import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/call_history.dart';
import '../models/contact_circle.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CallHistory> _history = [];
  List<ContactCircle> _circles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _history = DatabaseService.getAllHistory();
      _circles = DatabaseService.getAllCircles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique d\'appels'),
      ),
      body: SafeArea(
        child: _history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun appel enregistré',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final call = _history[index];
                  final circle = _circles.firstWhere(
                    (c) => c.id == call.circleId,
                    orElse: () => _circles.first,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(circle.colorHex))
                            .withValues(alpha: 0.2),
                        child: Icon(
                          Icons.phone,
                          color: Color(int.parse(circle.colorHex)),
                        ),
                      ),
                      title: Text(
                        call.contactName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm').format(call.callDate),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(circle.colorHex))
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  circle.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(int.parse(circle.colorHex)),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (call.notes != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.note, size: 14, color: Colors.grey),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(
                        call.getDurationFormatted(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      onTap: () => _showCallDetails(call, circle),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showCallDetails(CallHistory call, ContactCircle circle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(call.contactName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Date',
              DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(call.callDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Durée',
              call.getDurationFormatted(),
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Cercle',
              circle.name,
              Icons.group_work,
            ),
            if (call.notes != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(call.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
