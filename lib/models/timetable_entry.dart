import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'timetable_entry.g.dart';

@HiveType(typeId: 1)
class TimetableEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  List<int> repeatDays; // 1-7 for days of week

  @HiveField(6)
  bool isReminder;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  String color; // Hex color code

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  TimetableEntry({
    String? id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    List<int>? repeatDays,
    this.isReminder = false,
    this.isCompleted = false,
    this.color = '#3498db',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    repeatDays = repeatDays ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  get date => null;
  
  // Helper methods
  bool isHappeningNow() {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  
  bool isOnDay(DateTime date) {
    if (repeatDays.isEmpty) {
      // One-time event, check if it's on the specified date
      return startTime.year == date.year && 
             startTime.month == date.month && 
             startTime.day == date.day;
    } else {
      // Repeating event, check if it repeats on the day of week
      final dayOfWeek = date.weekday; // 1-7 (1 = Monday)
      return repeatDays.contains(dayOfWeek);
    }
  }
  
  Duration getDuration() {
    return endTime.difference(startTime);
  }
  
  void toggleCompletion() {
    isCompleted = !isCompleted;
    updatedAt = DateTime.now();
    save();
  }
}
