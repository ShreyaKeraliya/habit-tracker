import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/timetable_entry.dart';
import '../services/notification_service.dart';

class TimetableProvider with ChangeNotifier {
  late Box<TimetableEntry> _timetableBox;
  List<TimetableEntry> _entries = [];
  final NotificationService _notificationService = NotificationService();

  List<TimetableEntry> get entries => _entries;

  TimetableProvider() {
    _initialize();
  }


  Future<void> _initialize() async {
    _timetableBox = Hive.box<TimetableEntry>('timetable');
    _loadEntries();
  }

  void _loadEntries() {
    _entries = _timetableBox.values.toList();
    notifyListeners();
  }

  Future<void> addEntry(TimetableEntry entry) async {
    await _timetableBox.put(entry.id, entry);
    _loadEntries();
    if (entry.isReminder) {
      _scheduleNotification(entry);
    }
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    await _timetableBox.put(entry.id, entry);
    _loadEntries();
    if (entry.isReminder) {
      _cancelNotification(entry);
      _scheduleNotification(entry);
    } else {
      _cancelNotification(entry);
    }
  }

  Future<void> deleteEntry(String id) async {
    final entry = _timetableBox.get(id);
    if (entry != null) {
      if (entry.isReminder) {
        _cancelNotification(entry);
      }
      await _timetableBox.delete(id);
      _loadEntries();
    }
  }

  Future<void> toggleEntryCompletion(String id) async {
    final entry = _timetableBox.get(id);
    if (entry != null) {
      entry.toggleCompletion();
      notifyListeners();
    }
  }

  List<TimetableEntry> getEntriesForDay(DateTime date) {
    return _entries.where((entry) => entry.isOnDay(date)).toList();
  }

  List<TimetableEntry> getCurrentEntries() {
    final now = DateTime.now();
    return _entries.where((entry) => entry.isHappeningNow()).toList();
  }

  List<TimetableEntry> getUpcomingEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _entries.where((entry) {
      // Check if this entry happens today and is in the future
      if (entry.isOnDay(today) && entry.startTime.isAfter(now)) {
        return true;
      }
      
      // Otherwise, find the next occurrence of this entry
      if (entry.repeatDays.isNotEmpty) {
        final todayWeekday = now.weekday;
        for (int i = 1; i <= 7; i++) {
          final checkDay = (todayWeekday + i) % 7;
          if (checkDay == 0) continue; // Skip zero, weekday is 1-7
          if (entry.repeatDays.contains(checkDay)) {
            return true;
          }
        }
      }
      
      return false;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> _scheduleNotification(TimetableEntry entry) async {
    if (!entry.isReminder) return;
    
    if (entry.repeatDays.isEmpty) {
      // One-time reminder
      await _notificationService.scheduleOneTimeNotification(
        id: entry.id.hashCode,
        title: entry.title,
        body: entry.description.isNotEmpty
            ? entry.description
            : 'Time for your scheduled activity!',
        scheduledDate: entry.startTime.subtract(const Duration(minutes: 15)),
      );
    } else {
      // Repeating reminder
      for (final day in entry.repeatDays) {
        final hour = entry.startTime.hour;
        final minute = entry.startTime.minute;
        
        await _notificationService.scheduleWeeklyNotification(
          id: entry.id.hashCode + day, // Unique ID for each day
          title: entry.title,
          body: entry.description.isNotEmpty
              ? entry.description
              : 'Time for your scheduled activity!',
          hour: hour,
          minute: minute - 15, // 15 minutes before
          day: day,
        );
      }
    }
  }

  Future<void> _cancelNotification(TimetableEntry entry) async {
    if (entry.repeatDays.isEmpty) {
      await _notificationService.cancelNotification(entry.id.hashCode);
    } else {
      for (final day in entry.repeatDays) {
        await _notificationService.cancelNotification(entry.id.hashCode + day);
      }
    }
  }
}
