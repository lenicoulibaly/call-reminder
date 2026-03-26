import 'package:hive/hive.dart';

part 'call_history.g.dart';

@HiveType(typeId: 2)
class CallHistory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String contactId;

  @HiveField(2)
  String contactName;

  @HiveField(3)
  DateTime callDate;

  @HiveField(4)
  int durationSeconds;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String circleId;

  @HiveField(7)
  DateTime createdAt;

  CallHistory({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.callDate,
    required this.durationSeconds,
    this.notes,
    required this.circleId,
    required this.createdAt,
  });

  factory CallHistory.create({
    required String contactId,
    required String contactName,
    required DateTime callDate,
    required int durationSeconds,
    String? notes,
    required String circleId,
  }) {
    return CallHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactId: contactId,
      contactName: contactName,
      callDate: callDate,
      durationSeconds: durationSeconds,
      notes: notes,
      circleId: circleId,
      createdAt: DateTime.now(),
    );
  }

  String getDurationFormatted() {
    if (durationSeconds < 60) {
      return '$durationSeconds sec';
    } else if (durationSeconds < 3600) {
      final minutes = durationSeconds ~/ 60;
      final seconds = durationSeconds % 60;
      return '$minutes min $seconds sec';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours h $minutes min';
    }
  }
}
