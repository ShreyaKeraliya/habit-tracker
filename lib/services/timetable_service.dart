import 'package:hive/hive.dart';

import '../models/timetable_entry.dart';

class TimetableService {
  final _timetableBox = Hive.box<TimetableEntry>('timetable');
  
  // Get all entries
  List<TimetableEntry> getAllEntries() {
    return _timetableBox.values.toList();
  }
  
  // Get an entry by ID
  TimetableEntry? getEntryById(String id) {
    return _timetableBox.get(id);
  }
  
  // Save an entry
  Future<void> saveEntry(TimetableEntry entry) async {
    await _timetableBox.put(entry.id, entry);
  }
  
  // Delete an entry
  Future<void> deleteEntry(String id) async {
    await _timetableBox.delete(id);
  }
  
  // Get entries for a specific date
  List<TimetableEntry> getEntriesForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return _timetableBox.values.where((entry) {
      // Check if it's a one-time entry on this date
      if (entry.repeatDays.isEmpty) {
        final entryDate = DateTime(
          entry.startTime.year,
          entry.startTime.month,
          entry.startTime.day,
        );
        return entryDate.isAtSameMomentAs(targetDate);
      }
      
      // Check if it's a repeating entry that happens on this day of week
      return entry.repeatDays.contains(date.weekday);
    }).toList();
  }
  
  // Get entries happening now
  List<TimetableEntry> getCurrentEntries() {
    final now = DateTime.now();
    
    return _timetableBox.values.where((entry) {
      // Check if it's the right day
      if (!entry.isOnDay(now)) return false;
      
      // Check if it's the right time
      return now.isAfter(entry.startTime) && now.isBefore(entry.endTime);
    }).toList();
  }
  
  // Get upcoming entries
  List<TimetableEntry> getUpcomingEntries(int hours) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(hours: hours));
    
    return _timetableBox.values.where((entry) {
      // Check if it's the right day
      if (!entry.isOnDay(now)) return false;
      
      // Check if it's starting within the cutoff period
      return entry.startTime.isAfter(now) && entry.startTime.isBefore(cutoff);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  // Get conflicting entries
  List<TimetableEntry> getConflictingEntries(TimetableEntry newEntry) {
    // For one-time entries
    if (newEntry.repeatDays.isEmpty) {
      return _getConflictsForDate(
        newEntry.startTime, 
        newEntry.endTime, 
        newEntry.id
      );
    }
    
    // For repeating entries
    List<TimetableEntry> conflicts = [];
    for (final day in newEntry.repeatDays) {
      // Create a sample date for this day of week
      final now = DateTime.now();
      int daysToAdd = (day - now.weekday) % 7;
      if (daysToAdd == 0) daysToAdd = 7; // Look at next week if today
      
      final sampleDate = now.add(Duration(days: daysToAdd));
      
      // Create start and end times for this sample date
      final sampleStart = DateTime(
        sampleDate.year,
        sampleDate.month,
        sampleDate.day,
        newEntry.startTime.hour,
        newEntry.startTime.minute,
      );
      
      final sampleEnd = DateTime(
        sampleDate.year,
        sampleDate.month,
        sampleDate.day,
        newEntry.endTime.hour,
        newEntry.endTime.minute,
      );
      
      conflicts.addAll(
        _getConflictsForDate(sampleStart, sampleEnd, newEntry.id)
      );
    }
    
    return conflicts;
  }
  
  List<TimetableEntry> _getConflictsForDate(
    DateTime start, 
    DateTime end, 
    String excludeId
  ) {
    return _timetableBox.values.where((entry) {
      // Skip the entry we're checking against
      if (entry.id == excludeId) return false;
      
      // Check if it occurs on the same day
      if (!entry.isOnDay(start)) return false;
      
      // Check for time overlap
      bool overlapStart = entry.startTime.isBefore(end) && entry.startTime.isAfter(start);
      bool overlapEnd = entry.endTime.isBefore(end) && entry.endTime.isAfter(start);
      bool containsTimeRange = entry.startTime.isBefore(start) && entry.endTime.isAfter(end);
      
      return overlapStart || overlapEnd || containsTimeRange;
    }).toList();
  }
  
  // Get free time slots for a specific date
  List<Map<String, DateTime>> getFreeTimeSlots(
    DateTime date, 
    {int minDuration = 30} // minimum duration in minutes
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day, 7, 0); // Start at 7 AM
    final endOfDay = DateTime(date.year, date.month, date.day, 22, 0); // End at 10 PM
    
    // Get all entries for the date
    final entries = getEntriesForDate(date)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Build list of busy slots
    List<Map<String, DateTime>> busySlots = [];
    for (final entry in entries) {
      busySlots.add({
        'start': entry.startTime,
        'end': entry.endTime,
      });
    }
    
    // Merge overlapping busy slots
    busySlots = _mergeOverlapping(busySlots);
    
    // Find free slots
    List<Map<String, DateTime>> freeSlots = [];
    DateTime currentStart = startOfDay;
    
    for (final busy in busySlots) {
      // If there's enough time before this busy slot, add a free slot
      if (busy['start']!.difference(currentStart).inMinutes >= minDuration) {
        freeSlots.add({
          'start': currentStart,
          'end': busy['start']!,
        });
      }
      
      // Move current start time to the end of this busy slot
      currentStart = busy['end']!;
    }
    
    // Add final free slot if there's time left in the day
    if (endOfDay.difference(currentStart).inMinutes >= minDuration) {
      freeSlots.add({
        'start': currentStart,
        'end': endOfDay,
      });
    }
    
    return freeSlots;
  }
  
  List<Map<String, DateTime>> _mergeOverlapping(List<Map<String, DateTime>> slots) {
    if (slots.isEmpty) return [];
    
    // Sort by start time
    slots.sort((a, b) => a['start']!.compareTo(b['start']!));
    
    List<Map<String, DateTime>> merged = [];
    Map<String, DateTime> current = slots.first;
    
    for (int i = 1; i < slots.length; i++) {
      // If current slot overlaps with the next one
      if (current['end']!.isAfter(slots[i]['start']!)) {
        // Merge them by taking the later end time
        if (slots[i]['end']!.isAfter(current['end']!)) {
          current['end'] = slots[i]['end']!;
        }
      } else {
        // No overlap, add current to merged list and move on
        merged.add(current);
        current = slots[i];
      }
    }
    
    // Add the last merged slot
    merged.add(current);
    
    return merged;
  }
}
