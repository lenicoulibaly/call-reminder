import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/contact_item.dart';
import '../models/contact_circle.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<ContactCircle> _circles = [];
  String? _selectedCircleId;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  void _loadCircles() {
    setState(() {
      _circles = DatabaseService.getAllCircles();
      if (_circles.isNotEmpty) {
        _selectedCircleId = _circles.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate() && _selectedCircleId != null) {
      final contact = ContactItem.create(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        circleId: _selectedCircleId!,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      // Calculer la première date d'appel recommandée
      final circle = _circles.firstWhere((c) => c.id == _selectedCircleId);
      contact.updateNextCallDate(
        DateTime.now().add(Duration(days: circle.callFrequencyDays)),
      );

      await DatabaseService.addContact(contact);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact ajouté avec succès')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un contact'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo placeholder
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: Colors.white,
                            onPressed: () {
                              // Ajouter une photo (fonctionnalité future)
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+33 6 12 34 56 78',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de téléphone est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cercle
                DropdownButtonFormField<String>(
                  initialValue: _selectedCircleId,
                  decoration: const InputDecoration(
                    labelText: 'Cercle *',
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
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un cercle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Ajoutez des notes sur ce contact',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Info cercle
                if (_selectedCircleId != null) ...[
                  Card(
                    color: Colors.blue.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getCircleInfo(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Bouton d'enregistrement
                ElevatedButton.icon(
                  onPressed: _saveContact,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCircleInfo() {
    if (_selectedCircleId == null) return '';
    
    final circle = _circles.firstWhere((c) => c.id == _selectedCircleId);
    return 'Ce contact sera dans le cercle "${circle.name}". '
           'Fréquence d\'appel recommandée : tous les ${circle.callFrequencyDays} jours.';
  }
}
