# Call Reminder

Application mobile Flutter pour rappeler d'appeler ses proches avec gestion de cercles de contacts.

## 📱 Fonctionnalités

- **Gestion de cercles de contacts** : Organisez vos contacts en cercles (Famille, Amis, Travail, etc.)
- **Fréquences personnalisables** : Définissez des fréquences d'appel et de rappel pour chaque cercle
- **Liste de rappels** : Consultez vos rappels triés par priorité
- **Historique d'appels** : Suivez tous vos appels aux proches
- **Statistiques** : Visualisez vos statistiques d'appels avec des graphiques
- **Configuration complète** : Personnalisez les cercles, couleurs et icônes

## 🚀 Technologies utilisées

- **Flutter 3.35.4** - Framework de développement mobile
- **Dart 3.9.2** - Langage de programmation
- **Hive 2.2.3** - Base de données NoSQL locale
- **Provider** - Gestion d'état
- **FL Chart** - Graphiques et statistiques
- **Material Design 3** - Design moderne

## 📦 Installation

### Prérequis

- Flutter SDK (3.35.4 ou supérieur)
- Dart SDK (3.9.2 ou supérieur)

### Étapes d'installation

1. Clonez le dépôt :
```bash
git clone https://github.com/lenicoulibaly/call-reminder.git
cd call-reminder
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Générez les fichiers Hive :
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Lancez l'application :
```bash
flutter run
```

## 🏗️ Structure du projet

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── models/                      # Modèles de données
│   ├── contact_circle.dart     # Modèle de cercle de contacts
│   ├── contact_item.dart       # Modèle de contact
│   ├── call_history.dart       # Modèle d'historique d'appel
│   └── reminder.dart           # Modèle de rappel
├── screens/                     # Écrans de l'application
│   ├── home_screen.dart        # Écran d'accueil
│   ├── contacts_screen.dart    # Liste des contacts
│   ├── add_contact_screen.dart # Ajout de contact
│   ├── circle_contacts_screen.dart # Contacts par cercle
│   ├── history_screen.dart     # Historique d'appels
│   ├── statistics_screen.dart  # Statistiques
│   ├── settings_screen.dart    # Paramètres
│   └── edit_circle_screen.dart # Édition de cercle
└── services/
    └── database_service.dart   # Service de base de données
```

## 📊 Captures d'écran

L'application utilise un design Material Design moderne avec :
- Navigation en bas d'écran
- Cartes avec ombres douces
- Palette de couleurs cohérente (bleu primaire)
- Interface responsive

## 🎨 Cercles par défaut

L'application est livrée avec 3 cercles préconfigurés :

1. **Famille** (Bleu) - Appel tous les 7 jours
2. **Amis** (Vert) - Appel tous les 14 jours
3. **Travail** (Orange) - Appel tous les 30 jours

Vous pouvez créer vos propres cercles personnalisés avec :
- Nom personnalisé
- Couleur au choix (8 couleurs disponibles)
- Icône personnalisée (8 icônes disponibles)
- Fréquences d'appel et de rappel

## 🔧 Configuration

### Dépendances principales

```yaml
dependencies:
  hive: 2.2.3
  hive_flutter: 1.1.0
  provider: 6.1.5+1
  intl: ^0.19.0
  permission_handler: ^11.3.1
  flutter_contacts: ^1.1.9
  fl_chart: ^0.69.2
  url_launcher: ^6.3.1

dev_dependencies:
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
```

## 📱 Plateformes supportées

- ✅ Android
- ✅ Web
- 🔄 iOS (en cours)

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT.

## 👨‍💻 Auteur

**Leni Coulibaly**
- GitHub: [@lenicoulibaly](https://github.com/lenicoulibaly)

## 🙏 Remerciements

- Flutter et l'équipe Dart
- La communauté Flutter
- Tous les contributeurs de packages open-source utilisés

---

**Fait avec ❤️ en Flutter**
