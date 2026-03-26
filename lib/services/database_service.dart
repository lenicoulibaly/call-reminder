import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact_circle.dart';
import '../models/contact_item.dart';
import '../models/call_history.dart';
import '../models/reminder.dart';

class DatabaseService {
  static const String circlesBoxName = 'circles';
  static const String contactsBoxName = 'contacts';
  static const String historyBoxName = 'history';
  static const String remindersBoxName = 'reminders';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Enregistrer les adaptateurs Hive
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ContactCircleAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ContactItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CallHistoryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReminderAdapter());
    }

    // Ouvrir les boxes
    await Hive.openBox<ContactCircle>(circlesBoxName);
    await Hive.openBox<ContactItem>(contactsBoxName);
    await Hive.openBox<CallHistory>(historyBoxName);
    await Hive.openBox<Reminder>(remindersBoxName);

    // Initialiser avec des données par défaut si nécessaire
    await _initializeDefaultData();
  }

  static Future<void> _initializeDefaultData() async {
    final circlesBox = Hive.box<ContactCircle>(circlesBoxName);
    
    if (circlesBox.isEmpty) {
      // Créer des cercles par défaut
      final defaultCircles = [
        ContactCircle.create(
          name: 'Famille',
          colorHex: '0xFF2196F3', // Bleu
          callFrequencyDays: 7,
          reminderFrequencyDays: 3,
          iconName: 'family_restroom',
        ),
        ContactCircle.create(
          name: 'Amis',
          colorHex: '0xFF4CAF50', // Vert
          callFrequencyDays: 14,
          reminderFrequencyDays: 5,
          iconName: 'groups',
        ),
        ContactCircle.create(
          name: 'Travail',
          colorHex: '0xFFFF9800', // Orange
          callFrequencyDays: 30,
          reminderFrequencyDays: 7,
          iconName: 'work',
        ),
      ];

      for (var circle in defaultCircles) {
        await circlesBox.add(circle);
      }
    }
  }

  // Cercles
  static Box<ContactCircle> get circlesBox => Hive.box<ContactCircle>(circlesBoxName);
  
  static List<ContactCircle> getAllCircles() {
    return circlesBox.values.toList();
  }

  static Future<void> addCircle(ContactCircle circle) async {
    await circlesBox.add(circle);
  }

  static Future<void> updateCircle(ContactCircle circle) async {
    await circle.save();
  }

  static Future<void> deleteCircle(ContactCircle circle) async {
    await circle.delete();
  }

  // Contacts
  static Box<ContactItem> get contactsBox => Hive.box<ContactItem>(contactsBoxName);
  
  static List<ContactItem> getAllContacts() {
    return contactsBox.values.toList();
  }

  static List<ContactItem> getContactsByCircle(String circleId) {
    return contactsBox.values.where((c) => c.circleId == circleId).toList();
  }

  static Future<void> addContact(ContactItem contact) async {
    await contactsBox.add(contact);
  }

  static Future<void> updateContact(ContactItem contact) async {
    await contact.save();
  }

  static Future<void> deleteContact(ContactItem contact) async {
    await contact.delete();
  }

  // Historique
  static Box<CallHistory> get historyBox => Hive.box<CallHistory>(historyBoxName);
  
  static List<CallHistory> getAllHistory() {
    final history = historyBox.values.toList();
    history.sort((a, b) => b.callDate.compareTo(a.callDate));
    return history;
  }

  static List<CallHistory> getHistoryByContact(String contactId) {
    return historyBox.values
        .where((h) => h.contactId == contactId)
        .toList()
      ..sort((a, b) => b.callDate.compareTo(a.callDate));
  }

  static Future<void> addHistory(CallHistory history) async {
    await historyBox.add(history);
  }

  // Rappels
  static Box<Reminder> get remindersBox => Hive.box<Reminder>(remindersBoxName);
  
  static List<Reminder> getAllReminders() {
    return remindersBox.values.toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  static List<Reminder> getPendingReminders() {
    return remindersBox.values
        .where((r) => !r.isCompleted)
        .toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  static Future<void> addReminder(Reminder reminder) async {
    await remindersBox.add(reminder);
  }

  static Future<void> updateReminder(Reminder reminder) async {
    await reminder.save();
  }

  static Future<void> deleteReminder(Reminder reminder) async {
    await reminder.delete();
  }

  // Statistiques
  static Map<String, dynamic> getStatistics() {
    final contacts = getAllContacts();
    final history = getAllHistory();
    final circles = getAllCircles();

    final totalContacts = contacts.length;
    final totalCalls = history.length;
    final totalCircles = circles.length;

    // Calculer la durée totale des appels
    final totalDuration = history.fold<int>(
      0,
      (sum, h) => sum + h.durationSeconds,
    );

    // Calculer les appels par cercle
    final callsByCircle = <String, int>{};
    for (var h in history) {
      callsByCircle[h.circleId] = (callsByCircle[h.circleId] ?? 0) + 1;
    }

    // Trouver le contact le plus appelé
    final callsByContact = <String, int>{};
    for (var h in history) {
      callsByContact[h.contactId] = (callsByContact[h.contactId] ?? 0) + 1;
    }

    String? mostCalledContactId;
    int maxCalls = 0;
    callsByContact.forEach((contactId, count) {
      if (count > maxCalls) {
        maxCalls = count;
        mostCalledContactId = contactId;
      }
    });

    return {
      'totalContacts': totalContacts,
      'totalCalls': totalCalls,
      'totalCircles': totalCircles,
      'totalDurationSeconds': totalDuration,
      'callsByCircle': callsByCircle,
      'mostCalledContactId': mostCalledContactId,
      'mostCalledCount': maxCalls,
    };
  }
}
