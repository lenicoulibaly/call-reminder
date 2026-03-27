import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact_item.dart';
import 'database_service.dart';

/// Service d'import de contacts depuis le téléphone
/// 
/// Gère :
/// - La demande de permissions (via flutter_contacts natif)
/// - L'accès aux contacts du téléphone
/// - La détection de doublons
/// - L'import dans la base de données
class ContactImportService {
  static final ContactImportService _instance = ContactImportService._internal();
  factory ContactImportService() => _instance;
  ContactImportService._internal();

  /// Demande la permission d'accès aux contacts
  /// Retourne true si accordée, false sinon
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Récupère tous les contacts du téléphone
  /// 
  /// Retourne une liste de contacts ou null si permission refusée
  Future<List<Contact>?> getPhoneContacts() async {
    debugPrint('ContactImportService: Demande de permission flutter_contacts...');
    
    final granted = await FlutterContacts.requestPermission(readonly: true);
    debugPrint('ContactImportService: Permission accordée = $granted');
    
    if (!granted) {
      debugPrint('ContactImportService: Permission refusée - l\'utilisateur doit aller dans les paramètres');
      return null;
    }

    try {
      debugPrint('ContactImportService: Récupération des contacts...');
      
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      debugPrint('ContactImportService: ${contacts.length} contacts récupérés au total');
      
      final filtered = contacts.where((c) => c.phones.isNotEmpty).toList();
      debugPrint('ContactImportService: ${filtered.length} contacts avec numéro de téléphone');
      
      return filtered;
    } catch (e) {
      debugPrint('ContactImportService: Erreur = $e');
      return [];
    }
  }

  /// Vérifie si un numéro existe déjà dans la base de données
  /// 
  /// Retourne le contact existant si trouvé, null sinon
  ContactItem? findExistingContact(String phoneNumber) {
    final allContacts = DatabaseService.getAllContacts();
    
    // Normaliser le numéro pour la comparaison
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    
    for (final contact in allContacts) {
      final existingNormalized = _normalizePhoneNumber(contact.phoneNumber);
      if (existingNormalized == normalizedPhone) {
        return contact;
      }
    }
    
    return null;
  }

  /// Import un contact du téléphone dans l'application
  /// 
  /// [phoneContact] Le contact du téléphone à importer
  /// [circleId] L'ID du cercle auquel ajouter le contact
  /// 
  /// Retourne :
  /// - 'success' : Contact importé avec succès
  /// - 'duplicate' : Contact déjà existant
  /// - 'error' : Erreur lors de l'import
  Future<ImportResult> importContact(Contact phoneContact, String circleId) async {
    try {
      // Vérifier qu'il y a au moins un numéro
      if (phoneContact.phones.isEmpty) {
        return ImportResult(
          status: ImportStatus.error,
          message: 'Aucun numéro de téléphone',
        );
      }

      // Prendre le premier numéro disponible
      final phoneNumber = phoneContact.phones.first.number;

      // Vérifier les doublons
      final existing = findExistingContact(phoneNumber);
      if (existing != null) {
        return ImportResult(
          status: ImportStatus.duplicate,
          message: 'Contact déjà existant: ${existing.name}',
          existingContact: existing,
        );
      }

      // Créer le nouveau contact
      final newContact = ContactItem.create(
        name: phoneContact.displayName,
        phoneNumber: phoneNumber,
        circleId: circleId,
      );

      // Calculer la date du premier appel recommandé
      final circles = DatabaseService.getAllCircles();
      final circle = circles.firstWhere((c) => c.id == circleId);
      newContact.updateNextCallDate(
        DateTime.now().add(Duration(days: circle.callFrequencyDays)),
      );

      // Sauvegarder dans la base de données
      await DatabaseService.addContact(newContact);

      return ImportResult(
        status: ImportStatus.success,
        message: 'Contact importé avec succès',
        importedContact: newContact,
      );
    } catch (e) {
      return ImportResult(
        status: ImportStatus.error,
        message: 'Erreur: $e',
      );
    }
  }

  /// Import plusieurs contacts en lot
  /// 
  /// Retourne un résumé de l'import
  Future<BatchImportResult> importMultipleContacts(
    List<Contact> phoneContacts,
    String circleId,
  ) async {
    int successCount = 0;
    int duplicateCount = 0;
    int errorCount = 0;
    final List<String> errors = [];

    for (final phoneContact in phoneContacts) {
      final result = await importContact(phoneContact, circleId);
      
      switch (result.status) {
        case ImportStatus.success:
          successCount++;
          break;
        case ImportStatus.duplicate:
          duplicateCount++;
          break;
        case ImportStatus.error:
          errorCount++;
          errors.add('${phoneContact.displayName}: ${result.message}');
          break;
      }
    }

    return BatchImportResult(
      totalProcessed: phoneContacts.length,
      successCount: successCount,
      duplicateCount: duplicateCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Normalise un numéro de téléphone pour la comparaison
  /// 
  /// Supprime les espaces, tirets, parenthèses, etc.
  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
  }

  /// Recherche des contacts par nom
  Future<List<Contact>?> searchContacts(String query) async {
    final allContacts = await getPhoneContacts();
    if (allContacts == null) return null;

    // Filtrer par nom
    final searchQuery = query.toLowerCase();
    return allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(searchQuery);
    }).toList();
  }
}

/// Statut d'import d'un contact
enum ImportStatus {
  success,
  duplicate,
  error,
}

/// Résultat de l'import d'un contact
class ImportResult {
  final ImportStatus status;
  final String message;
  final ContactItem? importedContact;
  final ContactItem? existingContact;

  ImportResult({
    required this.status,
    required this.message,
    this.importedContact,
    this.existingContact,
  });
}

/// Résultat de l'import en lot
class BatchImportResult {
  final int totalProcessed;
  final int successCount;
  final int duplicateCount;
  final int errorCount;
  final List<String> errors;

  BatchImportResult({
    required this.totalProcessed,
    required this.successCount,
    required this.duplicateCount,
    required this.errorCount,
    required this.errors,
  });

  String getSummary() {
    return '''
Import terminé:
✅ $successCount importé(s)
⚠️  $duplicateCount doublon(s)
❌ $errorCount erreur(s)
''';
  }
}
