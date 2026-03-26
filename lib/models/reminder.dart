import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 3)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String contactId;

  @HiveField(2)
  String contactName;

  @HiveField(3)
  DateTime reminderDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String circleId;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? completedAt;

  Reminder({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.reminderDate,
    required this.isCompleted,
    required this.circleId,
    required this.createdAt,
    this.completedAt,
  });

  factory Reminder.create({
    required String contactId,
    required String contactName,
    required DateTime reminderDate,
    required String circleId,
  }) {
    return Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactId: contactId,
      contactName: contactName,
      reminderDate: reminderDate,
      isCompleted: false,
      circleId: circleId,
      createdAt: DateTime.now(),
    );
  }

  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  bool isOverdue() {
    return !isCompleted && DateTime.now().isAfter(reminderDate);
  }

  int getDaysUntilReminder() {
    return reminderDate.difference(DateTime.now()).inDays;
  }
}
