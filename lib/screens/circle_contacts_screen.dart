import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/contact_circle.dart';
import '../models/contact_item.dart';
import '../models/call_history.dart';
import 'add_contact_screen.dart';

class CircleContactsScreen extends StatefulWidget {
  final ContactCircle circle;

  const CircleContactsScreen({super.key, required this.circle});

  @override
  State<CircleContactsScreen> createState() => _CircleContactsScreenState();
}

class _CircleContactsScreenState extends State<CircleContactsScreen> {
  List<ContactItem> _contacts = [];
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    setState(() {
      _contacts = DatabaseService.getContactsByCircle(widget.circle.id);
      _contacts.sort((a, b) {
        // Trier par priorité (contacts en retard d'abord)
        if (a.isOverdue() && !b.isOverdue()) return -1;
        if (!a.isOverdue() && b.isOverdue()) return 1;
        
        // Puis par date de prochain appel
        if (a.nextCallDate == null && b.nextCallDate == null) return 0;
        if (a.nextCallDate == null) return 1;
        if (b.nextCallDate == null) return -1;
        return a.nextCallDate!.compareTo(b.nextCallDate!);
      });
    });
  }

  Future<void> _makeCall(ContactItem contact) async {
    final phoneNumber = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$phoneNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      
      // Attendre un peu avant d'afficher le dialogue
      await Future.delayed(const Duration(seconds: 1));
      
      // Afficher le dialogue de confirmation
      if (mounted) {
        _showCallConfirmationDialog(contact);
      }
    }
  }
  
  Future<void> _showCallConfirmationDialog(ContactItem contact) async {
    final noteController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('As-tu appelé ce contact ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Ajouter une note rapide...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, j\'ai appelé'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final history = CallHistory.create(
        contactId: contact.id,
        contactName: contact.name,
        callDate: DateTime.now(),
        durationSeconds: 0,
        circleId: contact.circleId,
        notes: noteController.text.trim().isEmpty 
            ? null 
            : noteController.text.trim(),
      );
      await DatabaseService.addHistory(history);
      
      contact.recordCall(DateTime.now());
      contact.updateNextCallDate(
        DateTime.now().add(Duration(days: widget.circle.callFrequencyDays)),
      );
      await contact.save();
      
      // Reprogrammer la notification
      await _notificationService.scheduleNotificationForContact(contact, widget.circle);
      
      _loadContacts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appel enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circleColor = Color(int.parse(widget.circle.colorHex));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circle.name),
        backgroundColor: circleColor.withValues(alpha: 0.1),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // En-tête du cercle
            Container(
              padding: const EdgeInsets.all(16),
              color: circleColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: circleColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconFromName(widget.circle.iconName),
                      color: circleColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.circle.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_contacts.length} contact(s)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appel tous les ${widget.circle.callFrequencyDays} jours',
                          style: TextStyle(
                            fontSize: 12,
                            color: circleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des contacts
            Expanded(
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
                            'Aucun contact dans ce cercle',
                            style: TextStyle(
                              fontSize: 18,
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
                        final isOverdue = contact.isOverdue();
                        final daysUntilCall = contact.getDaysUntilNextCall();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isOverdue 
                              ? Colors.red.withValues(alpha: 0.05)
                              : null,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: circleColor.withValues(alpha: 0.2),
                                  child: Text(
                                    contact.name.isNotEmpty 
                                        ? contact.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: circleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isOverdue)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
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
                                    Icon(
                                      isOverdue ? Icons.warning : Icons.schedule,
                                      size: 14,
                                      color: isOverdue ? Colors.red : Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOverdue
                                          ? 'En retard de ${daysUntilCall.abs()} jour(s)'
                                          : daysUntilCall == 0
                                              ? 'À appeler aujourd\'hui'
                                              : 'Dans $daysUntilCall jour(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOverdue ? Colors.red : Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.phone,
                                color: isOverdue ? Colors.red : Colors.green,
                              ),
                              onPressed: () => _makeCall(contact),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: circleColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactScreen(),
            ),
          ).then((_) => _loadContacts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'family_restroom':
        return Icons.family_restroom;
      case 'groups':
        return Icons.groups;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'sports':
        return Icons.sports_soccer;
      case 'restaurant':
        return Icons.restaurant;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.group;
    }
  }
}
