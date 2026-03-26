import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/contact_circle.dart';
import '../models/reminder.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'circle_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const _HomeTabScreen(),
    const ContactsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

class _HomeTabScreen extends StatefulWidget {
  const _HomeTabScreen();

  @override
  State<_HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<_HomeTabScreen> {
  List<ContactCircle> _circles = [];
  List<Reminder> _upcomingReminders = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _circles = DatabaseService.getAllCircles();
      _upcomingReminders = DatabaseService.getPendingReminders().take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Voir tous les rappels
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statistiques rapides
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  
                  // Rappels à venir
                  if (_upcomingReminders.isNotEmpty) ...[
                    _buildSectionHeader('Rappels à venir', Icons.alarm),
                    const SizedBox(height: 12),
                    _buildUpcomingReminders(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Cercles de contacts
                  _buildSectionHeader('Mes cercles', Icons.group_work),
                  const SizedBox(height: 12),
                  _buildCirclesList(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactsScreen(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter contact'),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = DatabaseService.getStatistics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Contacts',
                  stats['totalContacts'].toString(),
                  Icons.people,
                  const Color(0xFF2196F3),
                ),
                _buildStatItem(
                  'Appels',
                  stats['totalCalls'].toString(),
                  Icons.phone,
                  const Color(0xFF4CAF50),
                ),
                _buildStatItem(
                  'Cercles',
                  stats['totalCircles'].toString(),
                  Icons.group_work,
                  const Color(0xFFFF9800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingReminders() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _upcomingReminders.length,
      itemBuilder: (context, index) {
        final reminder = _upcomingReminders[index];
        final daysUntil = reminder.getDaysUntilReminder();
        final isOverdue = reminder.isOverdue();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOverdue 
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              child: Icon(
                isOverdue ? Icons.warning : Icons.alarm,
                color: isOverdue ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(reminder.contactName),
            subtitle: Text(
              isOverdue 
                  ? 'En retard de ${daysUntil.abs()} jour(s)'
                  : daysUntil == 0
                      ? 'Aujourd\'hui'
                      : 'Dans $daysUntil jour(s)',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                reminder.markAsCompleted();
                reminder.save();
                _loadData();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCirclesList() {
    if (_circles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.group_work_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun cercle pour le moment',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _circles.length,
      itemBuilder: (context, index) {
        final circle = _circles[index];
        final contactCount = DatabaseService.getContactsByCircle(circle.id).length;
        final circleColor = Color(int.parse(circle.colorHex));
        
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CircleContactsScreen(circle: circle),
                ),
              ).then((_) => _loadData());
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: circleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconFromName(circle.iconName),
                      color: circleColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    circle.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$contactCount contact(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tous les ${circle.callFrequencyDays}j',
                    style: TextStyle(
                      fontSize: 11,
                      color: circleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
}
