import 'package:hive/hive.dart';

import '../models/habit.dart';

class HabitService {
  final Box<Habit> _habitsBox = Hive.box<Habit>('habits');
  
  // Get all habits
  List<Habit> getAllHabits() {
    return _habitsBox.values.toList();
  }
  
  // Get a habit by ID
  Habit? getHabitById(String id) {
    return _habitsBox.get(id);
  }
  
  // Save a habit
  Future<void> saveHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
  }
  
  // Delete a habit
  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
  }
  
  // Get habits due today
  List<Habit> getHabitsDueToday() {
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1-7 (1 = Monday)
    
    return _habitsBox.values
        .where((habit) => habit.reminderDays.contains(dayOfWeek))
        .toList();
  }
  
  // Get habits completed today
  List<Habit> getHabitsCompletedToday() {
    return _habitsBox.values
        .where((habit) => habit.isCompletedToday())
        .toList();
  }
  
  // Get habits not completed today
  List<Habit> getHabitsNotCompletedToday() {
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1-7 (1 = Monday)
    
    return _habitsBox.values
        .where((habit) => 
          habit.reminderDays.contains(dayOfWeek) && 
          !habit.isCompletedToday()
        )
        .toList();
  }
  
  // Get top habits by streak
  List<Habit> getTopHabitsByStreak(int limit) {
    final habits = _habitsBox.values.toList();
    habits.sort((a, b) => b.streakCount.compareTo(a.streakCount));
    
    return habits.take(limit).toList();
  }
  
  // Get completion rate for the past week
  double getWeeklyCompletionRate() {
    final habits = _habitsBox.values.toList();
    if (habits.isEmpty) return 0.0;
    
    double totalRate = 0.0;
    for (final habit in habits) {
      totalRate += habit.getCompletionRateLastWeek();
    }
    
    return totalRate / habits.length;
  }
  
  // Get habits that need attention (low completion rate)
  List<Habit> getHabitsThatNeedAttention() {
    return _habitsBox.values
        .where((habit) => habit.getCompletionRateLastWeek() < 0.5)
        .toList();
  }
}
