import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/contact_import_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/contact_circle.dart';

/// Dialogue pour importer des contacts depuis le téléphone
class ImportContactsDialog extends StatefulWidget {
  const ImportContactsDialog({super.key});

  @override
  State<ImportContactsDialog> createState() => _ImportContactsDialogState();
}

class _ImportContactsDialogState extends State<ImportContactsDialog> {
  final _importService = ContactImportService();
  final _notificationService = NotificationService();
  
  List<Contact>? _phoneContacts;
  List<ContactCircle> _circles = [];
  String? _selectedCircleId;
  bool _loading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  final Set<String> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // Charger les cercles
    _circles = DatabaseService.getAllCircles();
    if (_circles.isNotEmpty) {
      _selectedCircleId = _circles.first.id;
    }

    // Charger les contacts du téléphone
    final contacts = await _importService.getPhoneContacts();
    
    debugPrint('ImportContactsDialog: Contacts reçus = ${contacts?.length}');
    
    if (contacts == null) {
      setState(() {
        _errorMessage = 'Accès aux contacts refusé.\n\nSi le dialogue de permission ne s\'est pas affiché, allez dans Paramètres > Applications > call_reminder > Permissions et activez "Contacts".';
        _loading = false;
      });
      return;
    }

    if (contacts.isEmpty) {
      debugPrint('ImportContactsDialog: La liste de contacts est vide');
    }

    setState(() {
      _phoneContacts = contacts;
      _loading = false;
    });
  }

  Future<void> _importSelectedContacts() async {
    if (_selectedContacts.isEmpty || _selectedCircleId == null) return;

    final selectedPhoneContacts = _phoneContacts!
        .where((c) => _selectedContacts.contains(c.id))
        .toList();

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Importer les contacts
    final result = await _importService.importMultipleContacts(
      selectedPhoneContacts,
      _selectedCircleId!,
    );

    // Reprogrammer les notifications pour les nouveaux contacts
    try {
      await _notificationService.rescheduleAllNotifications();
    } catch (e) {
      debugPrint('Erreur lors de la reprogrammation des notifications: $e');
    }

    // Fermer le dialogue de chargement
    if (mounted) Navigator.pop(context);

    // Afficher le résumé
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import terminé'),
          content: Text(result.getSummary()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le résumé
                Navigator.pop(context, result.successCount); // Retourner au caller
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Importer depuis téléphone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteur de cercle
            if (_circles.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedCircleId,
                decoration: const InputDecoration(
                  labelText: 'Ajouter au cercle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_work),
                ),
                items: _circles.map((circle) {
                  return DropdownMenuItem(
                    value: circle.id,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(int.parse(circle.colorHex)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(circle.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCircleId = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Compteur de sélection
            if (_selectedContacts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedContacts.length} contact(s) sélectionné(s)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Champ de recherche
            if (!_loading && _phoneContacts != null && _phoneContacts!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un contact...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

            // Liste des contacts
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.contacts,
                                size: 64,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Réessayer'),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => openAppSettings(),
                                icon: const Icon(Icons.settings),
                                label: const Text('Ouvrir les paramètres'),
                              ),
                            ],
                          ),
                        )
                      : _phoneContacts == null || _phoneContacts!.isEmpty
                          ? const Center(
                              child: Text('Aucun contact trouvé'),
                            )
                          : ListView.builder(
                              itemCount: _phoneContacts!
                                  .where((c) => c.displayName.toLowerCase().contains(_searchQuery))
                                  .length,
                              itemBuilder: (context, index) {
                                final filteredList = _phoneContacts!
                                    .where((c) => c.displayName.toLowerCase().contains(_searchQuery))
                                    .toList();
                                final contact = filteredList[index];
                                final isSelected = _selectedContacts.contains(contact.id);
                                
                                // Vérifier si c'est un doublon
                                final phoneNumber = contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : '';
                                final isDuplicate = phoneNumber.isNotEmpty &&
                                    _importService.findExistingContact(phoneNumber) != null;

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: isDuplicate
                                      ? null
                                      : (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedContacts.add(contact.id);
                                            } else {
                                              _selectedContacts.remove(contact.id);
                                            }
                                          });
                                        },
                                  title: Text(
                                    contact.displayName,
                                    style: TextStyle(
                                      color: isDuplicate ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    phoneNumber.isEmpty
                                        ? 'Aucun numéro'
                                        : isDuplicate
                                            ? '$phoneNumber (déjà existant)'
                                            : phoneNumber,
                                    style: TextStyle(
                                      color: isDuplicate ? Colors.grey : null,
                                    ),
                                  ),
                                  secondary: CircleAvatar(
                                    child: Text(
                                      contact.displayName.isNotEmpty
                                          ? contact.displayName[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            // Boutons d'action
            const SizedBox(height: 16),
            Row(
              children: [
                if (_phoneContacts != null && _phoneContacts!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedContacts.length == _phoneContacts!.length) {
                          _selectedContacts.clear();
                        } else {
                          _selectedContacts.addAll(
                            _phoneContacts!
                                .where((c) {
                                  final phone = c.phones.isNotEmpty
                                      ? c.phones.first.number
                                      : '';
                                  return phone.isNotEmpty &&
                                      _importService.findExistingContact(phone) == null;
                                })
                                .map((c) => c.id),
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedContacts.length == _phoneContacts!.length
                          ? 'Tout désélectionner'
                          : 'Tout sélectionner',
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _selectedContacts.isEmpty || _selectedCircleId == null
                      ? null
                      : _importSelectedContacts,
                  icon: const Icon(Icons.download),
                  label: const Text('Importer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
