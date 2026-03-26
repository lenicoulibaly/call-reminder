import 'package:hive/hive.dart';

part 'contact_item.g.dart';

@HiveType(typeId: 1)
class ContactItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  String circleId;

  @HiveField(4)
  DateTime? lastCallDate;

  @HiveField(5)
  DateTime? nextCallDate;

  @HiveField(6)
  String? photoPath;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  int totalCalls;

  ContactItem({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.circleId,
    this.lastCallDate,
    this.nextCallDate,
    this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.totalCalls = 0,
  });

  factory ContactItem.create({
    required String name,
    required String phoneNumber,
    required String circleId,
    String? photoPath,
    String? notes,
  }) {
    final now = DateTime.now();
    return ContactItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phoneNumber,
      circleId: circleId,
      photoPath: photoPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      totalCalls: 0,
    );
  }

  void recordCall(DateTime callDate) {
    lastCallDate = callDate;
    totalCalls++;
    updatedAt = DateTime.now();
  }

  void updateNextCallDate(DateTime date) {
    nextCallDate = date;
    updatedAt = DateTime.now();
  }

  int getDaysSinceLastCall() {
    if (lastCallDate == null) return -1;
    return DateTime.now().difference(lastCallDate!).inDays;
  }

  int getDaysUntilNextCall() {
    if (nextCallDate == null) return -1;
    return nextCallDate!.difference(DateTime.now()).inDays;
  }

  bool isOverdue() {
    if (nextCallDate == null) return false;
    return DateTime.now().isAfter(nextCallDate!);
  }
}
