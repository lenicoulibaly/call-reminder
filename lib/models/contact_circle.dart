import 'package:hive/hive.dart';

part 'contact_circle.g.dart';

@HiveType(typeId: 0)
class ContactCircle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String colorHex;

  @HiveField(3)
  int callFrequencyDays; // Fréquence d'appel en jours

  @HiveField(4)
  int reminderFrequencyDays; // Fréquence de rappel en jours

  @HiveField(5)
  String iconName;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  ContactCircle({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.callFrequencyDays,
    required this.reminderFrequencyDays,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactCircle.create({
    required String name,
    required String colorHex,
    required int callFrequencyDays,
    required int reminderFrequencyDays,
    required String iconName,
  }) {
    final now = DateTime.now();
    return ContactCircle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorHex: colorHex,
      callFrequencyDays: callFrequencyDays,
      reminderFrequencyDays: reminderFrequencyDays,
      iconName: iconName,
      createdAt: now,
      updatedAt: now,
    );
  }

  void updateCircle({
    String? name,
    String? colorHex,
    int? callFrequencyDays,
    int? reminderFrequencyDays,
    String? iconName,
  }) {
    if (name != null) this.name = name;
    if (colorHex != null) this.colorHex = colorHex;
    if (callFrequencyDays != null) this.callFrequencyDays = callFrequencyDays;
    if (reminderFrequencyDays != null) this.reminderFrequencyDays = reminderFrequencyDays;
    if (iconName != null) this.iconName = iconName;
    updatedAt = DateTime.now();
  }
}
