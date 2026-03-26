import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/contact_circle.dart';
import 'edit_circle_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ContactCircle> _circles = [];

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  void _loadCircles() {
    setState(() {
      _circles = DatabaseService.getAllCircles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Cercles
            const Text(
              'Gestion des cercles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._circles.map((circle) => _buildCircleCard(circle)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addNewCircle,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un cercle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Section Notifications
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Activer les notifications'),
                    subtitle: const Text('Recevoir des rappels d\'appel'),
                    value: true,
                    onChanged: (value) {
                      // TODO: Implémenter les notifications
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Heure des rappels'),
                    subtitle: const Text('10:00'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Configurer l'heure
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section À propos
            const Text(
              'À propos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version de l\'application'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Conditions d\'utilisation'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Politique de confidentialité'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleCard(ContactCircle circle) {
    final circleColor = Color(int.parse(circle.colorHex));
    final contactCount = DatabaseService.getContactsByCircle(circle.id).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: circleColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconFromName(circle.iconName), color: circleColor),
        ),
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$contactCount contact(s)'),
            const SizedBox(height: 4),
            Text(
              'Appel tous les ${circle.callFrequencyDays}j · Rappel tous les ${circle.reminderFrequencyDays}j',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCircle(circle),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCircle(circle),
            ),
          ],
        ),
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
      default:
        return Icons.group;
    }
  }

  void _addNewCircle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditCircleScreen(),
      ),
    ).then((_) => _loadCircles());
  }

  void _editCircle(ContactCircle circle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCircleScreen(circle: circle),
      ),
    ).then((_) => _loadCircles());
  }

  Future<void> _deleteCircle(ContactCircle circle) async {
    final contactCount = DatabaseService.getContactsByCircle(circle.id).length;

    if (contactCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impossible de supprimer'),
          content: Text(
            'Ce cercle contient $contactCount contact(s). '
            'Veuillez d\'abord déplacer ou supprimer ces contacts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cercle'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${circle.name}" ?'),
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
      await circle.delete();
      _loadCircles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cercle supprimé')),
        );
      }
    }
  }
}
