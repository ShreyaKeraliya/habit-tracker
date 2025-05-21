import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/timetable_entry.dart';
import '../providers/timetable_provider.dart';
import '../widgets/timetable_entry_card.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildScheduleForSelectedDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonShowsNext: false,
        titleCentered: true,
      ),
      // Custom event marker builder
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          // Get entries for this day
          final provider = Provider.of<TimetableProvider>(context, listen: false);
          final entries = provider.getEntriesForDay(date);
          
          if (entries.isEmpty) return null;
          
          return Positioned(
            bottom: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildScheduleForSelectedDay() {
    return Consumer<TimetableProvider>(
      builder: (context, timetableProvider, child) {
        final entries = timetableProvider.getEntriesForDay(_selectedDay);
        
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64.0,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'No entries for ${_getFormattedDate()}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Tap the + button to add an entry',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Sort entries by start time
        entries.sort((a, b) => a.startTime.compareTo(b!.startTime));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: entries.length + 1, // +1 for the date header
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            
            final entry = entries[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Dismissible(
                key: Key(entry.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: Text(
                          'Are you sure you want to delete "${entry.title}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  timetableProvider.deleteEntry(entry.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${entry.title} deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          timetableProvider.addEntry(entry);
                        },
                      ),
                    ),
                  );
                },
                child: TimetableEntryCard(
                  entry: entry,
                  onToggle: () {
                    timetableProvider.toggleEntryCompletion(entry.id);
                  },
                  onTap: () => _showEditEntryDialog(context, entry),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  String _getFormattedDate() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    
    if (selectedDate == today) {
      return 'Today, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
    } else if (selectedDate == yesterday) {
      return 'Yesterday, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
    } else {
      return '${days[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
    }
  }
  
  void _showAddEntryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    DateTime startDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      DateTime.now().hour,
      0,
    );
    
    DateTime endDate = startDate.add(const Duration(hours: 1));
    
    bool isReminder = false;
    List<int> repeatDays = [];
    String selectedColor = '#3498db'; // Default blue
    
    final colorOptions = [
      {'name': 'Blue', 'value': '#3498db'},
      {'name': 'Green', 'value': '#2ecc71'},
      {'name': 'Purple', 'value': '#9b59b6'},
      {'name': 'Orange', 'value': '#e67e22'},
      {'name': 'Red', 'value': '#e74c3c'},
      {'name': 'Turquoise', 'value': '#1abc9c'},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Schedule Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Study Session',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g., Review chapter 3',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        const Text(
                          'Start:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startDate),
                              );
                              
                              if (pickedTime != null) {
                                setState(() {
                                  startDate = DateTime(
                                    startDate.year,
                                    startDate.month,
                                    startDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  
                                  // Ensure end time is after start time
                                  if (endDate.isBefore(startDate) || 
                                      endDate.isAtSameMomentAs(startDate)) {
                                    endDate = startDate.add(const Duration(hours: 1));
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'End:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endDate),
                              );
                              
                              if (pickedTime != null) {
                                setState(() {
                                  final newEndDate = DateTime(
                                    endDate.year,
                                    endDate.month,
                                    endDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  
                                  // Ensure end time is after start time
                                  if (newEndDate.isAfter(startDate)) {
                                    endDate = newEndDate;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('End time must be after start time'),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'Color:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            children: colorOptions.map((color) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color['value'] as String;
                                  });
                                },
                                child: Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(color['value'] as String),
                                    shape: BoxShape.circle,
                                    border: selectedColor == color['value']
                                        ? Border.all(color: Colors.black, width: 2.0)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Checkbox(
                          value: isReminder,
                          onChanged: (value) {
                            setState(() {
                              isReminder = value ?? false;
                            });
                          },
                        ),
                        const Text('Set as reminder'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Repeat on:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          FilterChip(
                            label: Text(_getDayLabel(i)),
                            selected: repeatDays.contains(i),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  repeatDays.add(i);
                                } else {
                                  repeatDays.remove(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a title'),
                        ),
                      );
                      return;
                    }
                    
                    final entry = TimetableEntry(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      startTime: startDate,
                      endTime: endDate,
                      repeatDays: repeatDays,
                      isReminder: isReminder,
                      color: selectedColor,
                    );
                    
                    Provider.of<TimetableProvider>(context, listen: false)
                        .addEntry(entry);
                    
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showEditEntryDialog(BuildContext context, TimetableEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final descriptionController = TextEditingController(text: entry.description);
    
    DateTime startDate = entry.startTime;
    DateTime endDate = entry.endTime;
    
    bool isReminder = entry.isReminder;
    List<int> repeatDays = List<int>.from(entry.repeatDays);
    String selectedColor = entry.color;
    
    final colorOptions = [
      {'name': 'Blue', 'value': '#3498db'},
      {'name': 'Green', 'value': '#2ecc71'},
      {'name': 'Purple', 'value': '#9b59b6'},
      {'name': 'Orange', 'value': '#e67e22'},
      {'name': 'Red', 'value': '#e74c3c'},
      {'name': 'Turquoise', 'value': '#1abc9c'},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Schedule Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        const Text(
                          'Start:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startDate),
                              );
                              
                              if (pickedTime != null) {
                                setState(() {
                                  startDate = DateTime(
                                    startDate.year,
                                    startDate.month,
                                    startDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  
                                  // Ensure end time is after start time
                                  if (endDate.isBefore(startDate) || 
                                      endDate.isAtSameMomentAs(startDate)) {
                                    endDate = startDate.add(const Duration(hours: 1));
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'End:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endDate),
                              );
                              
                              if (pickedTime != null) {
                                setState(() {
                                  final newEndDate = DateTime(
                                    endDate.year,
                                    endDate.month,
                                    endDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  
                                  // Ensure end time is after start time
                                  if (newEndDate.isAfter(startDate)) {
                                    endDate = newEndDate;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('End time must be after start time'),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'Color:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            children: colorOptions.map((color) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color['value'] as String;
                                  });
                                },
                                child: Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(color['value'] as String),
                                    shape: BoxShape.circle,
                                    border: selectedColor == color['value']
                                        ? Border.all(color: Colors.black, width: 2.0)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Checkbox(
                          value: isReminder,
                          onChanged: (value) {
                            setState(() {
                              isReminder = value ?? false;
                            });
                          },
                        ),
                        const Text('Set as reminder'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Repeat on:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          FilterChip(
                            label: Text(_getDayLabel(i)),
                            selected: repeatDays.contains(i),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  repeatDays.add(i);
                                } else {
                                  repeatDays.remove(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a title'),
                        ),
                      );
                      return;
                    }
                    
                    // Update entry
                    entry.title = titleController.text.trim();
                    entry.description = descriptionController.text.trim();
                    entry.startTime = startDate;
                    entry.endTime = endDate;
                    entry.repeatDays = repeatDays;
                    entry.isReminder = isReminder;
                    entry.color = selectedColor;
                    entry.updatedAt = DateTime.now();
                    
                    Provider.of<TimetableProvider>(context, listen: false)
                        .updateEntry(entry);
                    
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  String _getDayLabel(int day) {
    switch (day) {
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      case 7: return 'S';
      default: return '';
    }
  }
  
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
