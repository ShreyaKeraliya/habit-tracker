import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({Key? key}) : super(key: key);

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        elevation: 0,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final habits = habitProvider.habits;
          
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 64.0,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'No habits added yet',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Add a habit to start tracking your progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHabitDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Habit'),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Habit statistics
                _buildHabitStatistics(habitProvider),
                const SizedBox(height: 16.0),
                
                // Habit list
                Expanded(
                  child: ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Dismissible(
                          key: Key(habit.id),
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
                                    'Are you sure you want to delete "${habit.name}"?',
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
                            habitProvider.deleteHabit(habit.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${habit.name} deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    habitProvider.addHabit(habit);
                                  },
                                ),
                              ),
                            );
                          },
                          child: HabitCard(
                            habit: habit,
                            onToggle: () {
                              habitProvider.toggleHabitCompletion(habit.id);
                            },
                            onTap: () => _showEditHabitDialog(context, habit),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildHabitStatistics(HabitProvider habitProvider) {
    final habits = habitProvider.habits;
    if (habits.isEmpty) return const SizedBox.shrink();
    
    // Calculate statistics
    final streakHabits = List<Habit>.from(habits);
    streakHabits.sort((a, b) => b.streakCount.compareTo(a.streakCount));
    
    final topStreak = streakHabits.isNotEmpty ? streakHabits.first.streakCount : 0;
    final completionRate = habitProvider.getAverageCompletionRate();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Completion Rate',
            value: '${(completionRate * 100).toStringAsFixed(0)}%',
            icon: Icons.insert_chart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildStatCard(
            title: 'Top Streak',
            value: '$topStreak days',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    // Default reminder time (9:00 AM)
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);
    
    // Default reminder days (all days selected)
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Habit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Habit Name',
                        hintText: 'e.g., Morning Run',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g., Run for 20 minutes',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Reminder Days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          FilterChip(
                            label: Text(_getDayLabel(i)),
                            selected: selectedDays.contains(i),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedDays.add(i);
                                } else {
                                  selectedDays.remove(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Reminder Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: reminderTime,
                        );
                        if (picked != null) {
                          setState(() {
                            reminderTime = picked;
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
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
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a habit name'),
                        ),
                      );
                      return;
                    }
                    
                    if (selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one day'),
                        ),
                      );
                      return;
                    }
                    
                    final habit = Habit(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      reminderDays: selectedDays,
                      reminderTime: '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
                    );
                    
                    Provider.of<HabitProvider>(context, listen: false)
                        .addHabit(habit);
                    
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
  
  void _showEditHabitDialog(BuildContext context, Habit habit) {
    final nameController = TextEditingController(text: habit.name);
    final descriptionController = TextEditingController(text: habit.description);
    
    // Parse reminder time
    final timeParts = habit.reminderTime.split(':');
    TimeOfDay reminderTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    
    // Copy reminder days
    List<int> selectedDays = List<int>.from(habit.reminderDays);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Habit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Habit Name',
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
                    const Text(
                      'Reminder Days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          FilterChip(
                            label: Text(_getDayLabel(i)),
                            selected: selectedDays.contains(i),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedDays.add(i);
                                } else {
                                  selectedDays.remove(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Reminder Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: reminderTime,
                        );
                        if (picked != null) {
                          setState(() {
                            reminderTime = picked;
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'Current Streak:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '${habit.streakCount} days',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
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
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a habit name'),
                        ),
                      );
                      return;
                    }
                    
                    if (selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one day'),
                        ),
                      );
                      return;
                    }
                    
                    // Update habit
                    habit.name = nameController.text.trim();
                    habit.description = descriptionController.text.trim();
                    habit.reminderDays = selectedDays;
                    habit.reminderTime = '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';
                    habit.updatedAt = DateTime.now();
                    
                    Provider.of<HabitProvider>(context, listen: false)
                        .updateHabit(habit);
                    
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
}
