import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/habit.dart';
import '../services/notification_service.dart';

class HabitProvider with ChangeNotifier {
  late Box<Habit> _habitsBox;
  List<Habit> _habits = [];
  final NotificationService _notificationService = NotificationService();

  List<Habit> get habits => _habits;

  HabitProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _habitsBox = Hive.box<Habit>('habits');
    _loadHabits();
  }

  void _loadHabits() {
    _habits = _habitsBox.values.toList();
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
    _loadHabits();
    _scheduleNotification(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
    _loadHabits();
    _cancelNotification(habit);
    _scheduleNotification(habit);
  }

  Future<void> deleteHabit(String id) async {
    final habit = _habitsBox.get(id);
    if (habit != null) {
      _cancelNotification(habit);
      await _habitsBox.delete(id);
      _loadHabits();
    }
  }

  Future<void> toggleHabitCompletion(String id) async {
    final habit = _habitsBox.get(id);
    if (habit != null) {
      if (habit.isCompletedToday()) {
        habit.markIncomplete();
      } else {
        habit.markComplete();
      }
      notifyListeners();
    }
  }

  Future<void> _scheduleNotification(Habit habit) async {
    // Parse reminder time
    final timeParts = habit.reminderTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Schedule notifications for each reminder day
    for (final day in habit.reminderDays) {
      await _notificationService.scheduleWeeklyNotification(
        id: habit.id.hashCode + day, // Unique ID for each day
        title: 'Time for ${habit.name}',
        body: habit.description.isNotEmpty
            ? habit.description
            : 'Don\'t forget to complete your habit!',
        hour: hour,
        minute: minute,
        day: day,
      );
    }
  }

  Future<void> _cancelNotification(Habit habit) async {
    for (final day in habit.reminderDays) {
      await _notificationService.cancelNotification(habit.id.hashCode + day);
    }
  }

  // Analytics methods to help with AI suggestions
  double getAverageCompletionRate() {
    if (_habits.isEmpty) return 0.0;
    
    final sum = _habits.fold<double>(
      0.0, 
      (sum, habit) => sum + habit.getCompletionRateLastWeek()
    );
    
    return sum / _habits.length;
  }

  List<Habit> getLeastCompletedHabits() {
    if (_habits.isEmpty) return [];
    
    final sortedHabits = List<Habit>.from(_habits);
    sortedHabits.sort((a, b) => 
      a.getCompletionRateLastWeek().compareTo(b.getCompletionRateLastWeek())
    );
    
    return sortedHabits.take(3).toList();
  }

  List<Habit> getMostCompletedHabits() {
    if (_habits.isEmpty) return [];
    
    final sortedHabits = List<Habit>.from(_habits);
    sortedHabits.sort((a, b) => 
      b.getCompletionRateLastWeek().compareTo(a.getCompletionRateLastWeek())
    );
    
    return sortedHabits.take(3).toList();
  }
}
