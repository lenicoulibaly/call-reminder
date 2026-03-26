import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/contact_item.dart';
import '../models/contact_circle.dart';
import 'database_service.dart';

/// Service de gestion des notifications locales
/// 
/// Ce service gère :
/// - L'initialisation des notifications (Android + iOS)
/// - La programmation de notifications pour les rappels d'appels
/// - L'annulation et la mise à jour des notifications
/// - La reprogrammation au redémarrage de l'app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialise le service de notifications
  /// 
  /// Doit être appelé au démarrage de l'application
  /// Configure les paramètres Android et iOS
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les timezones pour les notifications programmées
    tz.initializeTimeZones();
    
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser avec callback pour les clics sur notification
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;

    // Demander les permissions (Android 13+)
    await _requestPermissions();

    // Reprogrammer les notifications existantes
    await rescheduleAllNotifications();
  }

  /// Demande les permissions de notification
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Callback appelé lors du clic sur une notification
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigation vers le contact concerné
    // On pourrait récupérer l'ID du contact depuis response.payload
  }

  /// Programme une notification pour un contact
  /// 
  /// [contact] Le contact pour lequel programmer la notification
  /// [circle] Le cercle du contact (pour afficher le nom)
  Future<void> scheduleNotificationForContact(
    ContactItem contact,
    ContactCircle circle,
  ) async {
    if (!_initialized) await initialize();

    // Annuler l'ancienne notification si elle existe
    await cancelNotification(contact.id);

    // Si pas de date de prochain appel, ne rien faire
    if (contact.nextCallDate == null) return;

    final notificationId = _getNotificationId(contact.id);
    final scheduledDate = contact.nextCallDate!;

    // Déterminer si la notification doit être immédiate (retard)
    final now = DateTime.now();
    final isOverdue = scheduledDate.isBefore(now);

    if (isOverdue) {
      // Notification immédiate pour les rappels en retard
      await _showImmediateNotification(
        notificationId,
        contact.name,
        circle.name,
        contact.id,
      );
    } else {
      // Programmer la notification pour la date prévue
      await _scheduleFutureNotification(
        notificationId,
        contact.name,
        circle.name,
        scheduledDate,
        contact.id,
      );
    }
  }

  /// Affiche une notification immédiate
  Future<void> _showImmediateNotification(
    int id,
    String contactName,
    String circleName,
    String contactId,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'call_reminders',
      'Rappels d\'appels',
      channelDescription: 'Notifications pour les rappels d\'appels aux proches',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'Rappel d\'appel en retard ⏰',
      'Tu devais appeler $contactName ($circleName)',
      details,
      payload: contactId,
    );
  }

  /// Programme une notification future
  Future<void> _scheduleFutureNotification(
    int id,
    String contactName,
    String circleName,
    DateTime scheduledDate,
    String contactId,
  ) async {
    // Programmer pour 10h du matin le jour prévu
    final notificationDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      10, // 10h du matin
      0,
    );

    final tzDate = tz.TZDateTime.from(notificationDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'call_reminders',
      'Rappels d\'appels',
      channelDescription: 'Notifications pour les rappels d\'appels aux proches',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Rappel d\'appel 📞',
      'Tu dois appeler $contactName aujourd\'hui ($circleName)',
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: contactId,
    );
  }

  /// Annule une notification pour un contact
  Future<void> cancelNotification(String contactId) async {
    if (!_initialized) await initialize();
    final notificationId = _getNotificationId(contactId);
    await _notifications.cancel(notificationId);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Reprogramme toutes les notifications pour les contacts existants
  /// 
  /// Appelé au démarrage de l'app pour restaurer les notifications
  /// après un redémarrage du téléphone
  Future<void> rescheduleAllNotifications() async {
    if (!_initialized) await initialize();

    // Annuler toutes les anciennes notifications
    await cancelAllNotifications();

    // Récupérer tous les contacts et cercles
    final contacts = DatabaseService.getAllContacts();
    final circles = DatabaseService.getAllCircles();

    // Créer un map des cercles pour accès rapide
    final circleMap = {for (var c in circles) c.id: c};

    // Reprogrammer une notification pour chaque contact
    for (final contact in contacts) {
      if (contact.nextCallDate != null) {
        final circle = circleMap[contact.circleId];
        if (circle != null) {
          await scheduleNotificationForContact(contact, circle);
        }
      }
    }
  }

  /// Convertit un ID de contact en ID de notification unique
  /// 
  /// Utilise un hash simple pour garantir l'unicité
  int _getNotificationId(String contactId) {
    // Simple hash de l'ID du contact pour obtenir un int unique
    int hash = 0;
    for (int i = 0; i < contactId.length; i++) {
      hash = ((hash << 5) - hash) + contactId.codeUnitAt(i);
      hash = hash & hash; // Convertir en 32bit integer
    }
    return hash.abs();
  }

  /// Teste les notifications (utile pour debug)
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'call_reminders',
      'Rappels d\'appels',
      channelDescription: 'Notifications pour les rappels d\'appels aux proches',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999,
      'Test de notification',
      'Si tu vois ce message, les notifications fonctionnent !',
      details,
    );
  }
}
