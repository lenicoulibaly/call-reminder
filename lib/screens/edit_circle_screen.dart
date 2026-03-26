import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/contact_circle.dart';

class EditCircleScreen extends StatefulWidget {
  final ContactCircle? circle;

  const EditCircleScreen({super.key, this.circle});

  @override
  State<EditCircleScreen> createState() => _EditCircleScreenState();
}

class _EditCircleScreenState extends State<EditCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _callFrequencyController;
  late TextEditingController _reminderFrequencyController;

  Color _selectedColor = const Color(0xFF2196F3);
  String _selectedIcon = 'groups';

  final List<Color> _availableColors = [
    const Color(0xFF2196F3), // Bleu
    const Color(0xFF4CAF50), // Vert
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Rouge
    const Color(0xFF9C27B0), // Violet
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFFEB3B), // Jaune
    const Color(0xFF795548), // Marron
  ];

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'family_restroom', 'icon': Icons.family_restroom},
    {'name': 'groups', 'icon': Icons.groups},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'favorite', 'icon': Icons.favorite},
    {'name': 'sports', 'icon': Icons.sports_soccer},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'music', 'icon': Icons.music_note},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.circle?.name ?? '');
    _callFrequencyController = TextEditingController(
      text: widget.circle?.callFrequencyDays.toString() ?? '7',
    );
    _reminderFrequencyController = TextEditingController(
      text: widget.circle?.reminderFrequencyDays.toString() ?? '3',
    );

    if (widget.circle != null) {
      _selectedColor = Color(int.parse(widget.circle!.colorHex));
      _selectedIcon = widget.circle!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _callFrequencyController.dispose();
    _reminderFrequencyController.dispose();
    super.dispose();
  }

  Future<void> _saveCircle() async {
    if (_formKey.currentState!.validate()) {
      if (widget.circle == null) {
        // Créer un nouveau cercle
        final circle = ContactCircle.create(
          name: _nameController.text.trim(),
          colorHex: '0x${_selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
          callFrequencyDays: int.parse(_callFrequencyController.text),
          reminderFrequencyDays: int.parse(_reminderFrequencyController.text),
          iconName: _selectedIcon,
        );
        await DatabaseService.addCircle(circle);
      } else {
        // Modifier un cercle existant
        widget.circle!.updateCircle(
          name: _nameController.text.trim(),
          colorHex: '0x${_selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
          callFrequencyDays: int.parse(_callFrequencyController.text),
          reminderFrequencyDays: int.parse(_reminderFrequencyController.text),
          iconName: _selectedIcon,
        );
        await widget.circle!.save();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.circle == null
                ? 'Cercle créé avec succès'
                : 'Cercle modifié avec succès'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circle == null ? 'Nouveau cercle' : 'Modifier le cercle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nom du cercle
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du cercle *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Fréquence d'appel
                TextFormField(
                  controller: _callFrequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence d\'appel (jours) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: '7',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La fréquence est requise';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Veuillez entrer un nombre positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fréquence de rappel
                TextFormField(
                  controller: _reminderFrequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence de rappel (jours) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notifications),
                    hintText: '3',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La fréquence de rappel est requise';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Veuillez entrer un nombre positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sélection de couleur
                const Text(
                  'Couleur du cercle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Sélection d'icône
                const Text(
                  'Icône du cercle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableIcons.map((iconData) {
                    final isSelected = _selectedIcon == iconData['name'];
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconData['name'] as String),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: isSelected ? _selectedColor : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Bouton de sauvegarde
                ElevatedButton.icon(
                  onPressed: _saveCircle,
                  icon: const Icon(Icons.save),
                  label: Text(widget.circle == null ? 'Créer' : 'Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
