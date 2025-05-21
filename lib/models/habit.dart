import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<bool> completionStatus; // Index represents day of the week (0 = Monday)

  @HiveField(4)
  List<DateTime> completionDates;

  @HiveField(5)
  List<int> reminderDays; // 1-7 for days of week

  @HiveField(6)
  String reminderTime; // Format: "HH:MM"

  @HiveField(7)
  int streakCount;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  Habit({
    String? id,
    required this.name,
    this.description = '',
    List<bool>? completionStatus,
    List<DateTime>? completionDates,
    List<int>? reminderDays,
    this.reminderTime = '09:00',
    this.streakCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    completionStatus = completionStatus ?? List.filled(7, false),
    completionDates = completionDates ?? [],
    reminderDays = reminderDays ?? [1, 2, 3, 4, 5, 6, 7],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
  
  // Helper methods
  bool isCompletedToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    return completionDates.any((date) => 
      date.year == todayDate.year && 
      date.month == todayDate.month && 
      date.day == todayDate.day
    );
  }
  
  void markComplete() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (!isCompletedToday()) {
      completionDates.add(todayDate);
      
      // Update streak count
      if (_wasCompletedYesterday()) {
        streakCount++;
      } else {
        streakCount = 1;
      }
      
      final dayOfWeek = today.weekday - 1; // 0-6
      completionStatus[dayOfWeek] = true;
      
      updatedAt = DateTime.now();
      save();
    }
  }
  
  void markIncomplete() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    completionDates.removeWhere((date) => 
      date.year == todayDate.year && 
      date.month == todayDate.month && 
      date.day == todayDate.day
    );
    
    final dayOfWeek = today.weekday - 1; // 0-6
    completionStatus[dayOfWeek] = false;
    
    // Reset streak if today was marked incomplete
    if (!_wasCompletedYesterday()) {
      streakCount = 0;
    }
    
    updatedAt = DateTime.now();
    save();
  }
  
  bool _wasCompletedYesterday() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    return completionDates.any((date) => 
      date.year == yesterdayDate.year && 
      date.month == yesterdayDate.month && 
      date.day == yesterdayDate.day
    );
  }
  
  double getCompletionRateLastWeek() {
    final today = DateTime.now();
    int completedDays = 0;
    
    for (int i = 0; i < 7; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final checkDateTime = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      bool completed = completionDates.any((date) => 
        date.year == checkDateTime.year && 
        date.month == checkDateTime.month && 
        date.day == checkDateTime.day
      );
      
      if (completed) {
        completedDays++;
      }
    }
    
    return completedDays / 7;
  }
}
