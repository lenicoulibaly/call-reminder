import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../models/contact_item.dart';
import '../models/contact_circle.dart';
import '../models/call_history.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactItem> _contacts = [];
  List<ContactCircle> _circles = [];
  String? _selectedCircleId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _circles = DatabaseService.getAllCircles();
      if (_selectedCircleId == null) {
        _contacts = DatabaseService.getAllContacts();
      } else {
        _contacts = DatabaseService.getContactsByCircle(_selectedCircleId!);
      }
      _contacts.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _makeCall(ContactItem contact) async {
    final phoneNumber = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$phoneNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      
      // Enregistrer l'appel
      final history = CallHistory.create(
        contactId: contact.id,
        contactName: contact.name,
        callDate: DateTime.now(),
        durationSeconds: 0, // Durée fictive
        circleId: contact.circleId,
      );
      await DatabaseService.addHistory(history);
      
      // Mettre à jour le contact
      contact.recordCall(DateTime.now());
      
      // Calculer la prochaine date d'appel
      final circle = _circles.firstWhere((c) => c.id == contact.circleId);
      contact.updateNextCallDate(
        DateTime.now().add(Duration(days: circle.callFrequencyDays)),
      );
      await contact.save();
      
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appel enregistré')),
        );
      }
    }
  }

  void _filterByCircle(String? circleId) {
    setState(() {
      _selectedCircleId = circleId;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterByCircle,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tous les contacts'),
              ),
              ..._circles.map((circle) => PopupMenuItem(
                value: circle.id,
                child: Row(
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
                    Text(circle.name),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _contacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun contact',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez votre premier contact',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  final circle = _circles.firstWhere(
                    (c) => c.id == contact.circleId,
                    orElse: () => _circles.first,
                  );
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(circle.colorHex))
                            .withValues(alpha: 0.2),
                        child: Text(
                          contact.name.isNotEmpty 
                              ? contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Color(int.parse(circle.colorHex)),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.phoneNumber),
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
                              const SizedBox(width: 8),
                              if (contact.lastCallDate != null)
                                Text(
                                  'Dernier appel: il y a ${contact.getDaysSinceLastCall()} jour(s)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: contact.isOverdue() ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _makeCall(contact),
                      ),
                      onTap: () {
                        // Voir les détails du contact
                        _showContactDetails(contact, circle);
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactScreen(),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showContactDetails(ContactItem contact, ContactCircle circle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 40,
                backgroundColor: Color(int.parse(circle.colorHex))
                    .withValues(alpha: 0.2),
                child: Text(
                  contact.name.isNotEmpty 
                      ? contact.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(int.parse(circle.colorHex)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                contact.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contact.phoneNumber,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Cercle', circle.name, Icons.group_work),
              _buildDetailRow(
                'Total d\'appels',
                contact.totalCalls.toString(),
                Icons.phone,
              ),
              if (contact.lastCallDate != null)
                _buildDetailRow(
                  'Dernier appel',
                  'Il y a ${contact.getDaysSinceLastCall()} jour(s)',
                  Icons.history,
                ),
              if (contact.nextCallDate != null)
                _buildDetailRow(
                  'Prochain appel',
                  contact.isOverdue()
                      ? 'En retard de ${contact.getDaysUntilNextCall().abs()} jour(s)'
                      : 'Dans ${contact.getDaysUntilNextCall()} jour(s)',
                  Icons.alarm,
                  textColor: contact.isOverdue() ? Colors.red : null,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _makeCall(contact);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteContact(contact);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(ContactItem contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${contact.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await contact.delete();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact supprimé')),
        );
      }
    }
  }
}
