import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../models/contact_circle.dart';
import '../models/contact_item.dart';
import '../services/database_service.dart';
import '../services/contact_import_service.dart';
import '../services/notification_service.dart';

/// Écran affichant tous les contacts du téléphone avec possibilité de les assigner aux cercles
class PhoneContactsScreen extends StatefulWidget {
  const PhoneContactsScreen({super.key});

  @override
  State<PhoneContactsScreen> createState() => _PhoneContactsScreenState();
}

class _PhoneContactsScreenState extends State<PhoneContactsScreen> {
  final _contactService = ContactImportService();
  final _notificationService = NotificationService();
  
  List<fc.Contact> _phoneContacts = [];
  List<ContactCircle> _circles = [];
  Map<String, String> _assignedCircles = {}; // phoneNumber -> circleId
  Map<String, ContactItem> _existingContacts = {}; // phoneNumber -> ContactItem
  bool _isLoading = true;
  bool _permissionDenied = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (kIsWeb) {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    try {
      // Charger les cercles
      _circles = DatabaseService.getAllCircles();
      
      // Charger les contacts existants dans l'app
      final existingContacts = DatabaseService.getAllContacts();
      _existingContacts.clear();
      for (var contact in existingContacts) {
        final normalizedPhone = _normalizePhoneNumber(contact.phoneNumber);
        _existingContacts[normalizedPhone] = contact;
        _assignedCircles[normalizedPhone] = contact.circleId;
      }

      // Demander la permission et charger les contacts du téléphone
      final hasPermission = await _contactService.requestPermission();
      
      if (!hasPermission) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      final contacts = await _contactService.getPhoneContacts();
      
      setState(() {
        _phoneContacts = contacts ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  bool _isContactInApp(fc.Contact contact) {
    for (var phone in contact.phones) {
      final normalized = _normalizePhoneNumber(phone.number);
      if (_existingContacts.containsKey(normalized)) {
        return true;
      }
    }
    return false;
  }

  String? _getContactCircleId(fc.Contact contact) {
    for (var phone in contact.phones) {
      final normalized = _normalizePhoneNumber(phone.number);
      if (_assignedCircles.containsKey(normalized)) {
        return _assignedCircles[normalized];
      }
    }
    return null;
  }

  Future<void> _assignToCircle(fc.Contact contact, String circleId) async {
    if (contact.phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce contact n\'a pas de numéro de téléphone'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final phoneNumber = contact.phones.first.number;
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    
    // Vérifier si le contact existe déjà
    if (_existingContacts.containsKey(normalizedPhone)) {
      // Mettre à jour le cercle du contact existant
      final existingContact = _existingContacts[normalizedPhone]!;
      existingContact.circleId = circleId;
      
      // Recalculer la prochaine date d'appel
      final circle = _circles.firstWhere((c) => c.id == circleId);
      final now = DateTime.now();
      existingContact.updateNextCallDate(
        now.add(Duration(days: circle.callFrequencyDays)),
      );
      
      await existingContact.save();
      
      // Reprogrammer la notification
      await _notificationService.scheduleNotificationForContact(existingContact, circle);
      
      setState(() {
        _assignedCircles[normalizedPhone] = circleId;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${contact.displayName} déplacé vers ${circle.name}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      // Créer un nouveau contact
      final circle = _circles.firstWhere((c) => c.id == circleId);
      final now = DateTime.now();
      
      final newContact = ContactItem.create(
        name: contact.displayName,
        phoneNumber: phoneNumber,
        circleId: circleId,
      );
      
      // Définir la prochaine date d'appel
      newContact.nextCallDate = now.add(Duration(days: circle.callFrequencyDays));
      
      await DatabaseService.addContact(newContact);
      
      // Programmer la notification
      await _notificationService.scheduleNotificationForContact(newContact, circle);
      
      setState(() {
        _existingContacts[normalizedPhone] = newContact;
        _assignedCircles[normalizedPhone] = circleId;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${contact.displayName} ajouté à ${circle.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeFromCircle(fc.Contact contact) async {
    if (contact.phones.isEmpty) return;
    
    final phoneNumber = contact.phones.first.number;
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    
    if (_existingContacts.containsKey(normalizedPhone)) {
      final existingContact = _existingContacts[normalizedPhone]!;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retirer le contact'),
          content: Text(
            'Voulez-vous retirer ${contact.displayName} de vos rappels d\'appel ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Retirer'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await existingContact.delete();
        await _notificationService.cancelNotification(existingContact.id);
        
        setState(() {
          _existingContacts.remove(normalizedPhone);
          _assignedCircles.remove(normalizedPhone);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${contact.displayName} retiré de vos rappels'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  List<fc.Contact> _getFilteredContacts() {
    if (_searchQuery.isEmpty) {
      return _phoneContacts;
    }
    
    final query = _searchQuery.toLowerCase();
    return _phoneContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query) ||
             contact.phones.any((phone) => phone.number.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts du téléphone'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (kIsWeb || _permissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              kIsWeb 
                  ? 'Fonctionnalité non disponible sur Web'
                  : 'Permission refusée',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Utilisez l\'application Android pour accéder aux contacts'
                  : 'Veuillez autoriser l\'accès aux contacts',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des contacts...'),
          ],
        ),
      );
    }

    final filteredContacts = _getFilteredContacts();

    if (filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'Aucun contact trouvé'
                  : 'Aucun résultat',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        final circleId = _getContactCircleId(contact);
        final isInApp = _isContactInApp(contact);
        
        ContactCircle? assignedCircle;
        if (circleId != null) {
          try {
            assignedCircle = _circles.firstWhere((c) => c.id == circleId);
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: assignedCircle != null
                  ? Color(int.parse(assignedCircle.colorHex)).withValues(alpha: 0.2)
                  : Colors.grey[300],
              child: assignedCircle != null
                  ? Text(
                      assignedCircle.iconName,
                      style: TextStyle(
                        color: Color(int.parse(assignedCircle.colorHex)),
                        fontSize: 20,
                      ),
                    )
                  : Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              contact.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.phones.isNotEmpty)
                  Text(contact.phones.first.number),
                const SizedBox(height: 4),
                if (assignedCircle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse(assignedCircle.colorHex))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignedCircle.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(int.parse(assignedCircle.colorHex)),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Non assigné',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isInApp
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'remove') {
                        _removeFromCircle(contact);
                      } else {
                        _assignToCircle(contact, value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Retirer'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
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
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Assigner à un cercle',
                    onSelected: (circleId) {
                      _assignToCircle(contact, circleId);
                    },
                    itemBuilder: (context) => _circles.map((circle) {
                      return PopupMenuItem(
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
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }
}
