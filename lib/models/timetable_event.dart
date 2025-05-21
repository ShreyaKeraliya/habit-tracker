import 'package:hive/hive.dart';
import 'package:flutter/material.dart';


@HiveType(typeId: 2)
class TimetableEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  Color color;

  @HiveField(6)
  bool isRecurring;

  @HiveField(7)
  List<int> recurringDays; // 0 = Monday, 1 = Tuesday, etc.

  @HiveField(8)
  bool hasReminder;

  @HiveField(9)
  int reminderMinutesBefore;

  TimetableEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isRecurring = false,
    this.recurringDays = const [],
    this.hasReminder = false,
    this.reminderMinutesBefore = 15,
  });

  // Convert to a map for easier handling
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'color': color.value,
      'isRecurring': isRecurring,
      'recurringDays': recurringDays,
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  // Get duration of the event
  Duration get duration => endTime.difference(startTime);



  // Check if event is happening now
  bool isHappeningNow() {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Check if event is for today
  bool isToday() {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // Check if event is happening on a specific day
  bool isOnDay(DateTime day) {
    if (isRecurring) {
      // Check if the event is recurring on this day of week
      return recurringDays.contains(day.weekday - 1);
    } else {
      // Check if the event is on this specific date
      return startTime.year == day.year &&
          startTime.month == day.month &&
          startTime.day == day.day;
    }
  }
}

// Color adapter for Hive
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 3;

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}
