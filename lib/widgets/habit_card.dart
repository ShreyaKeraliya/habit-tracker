import 'package:flutter/material.dart';

import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool showDetails;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onToggle,
    this.onTap,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isCompleted
              ? theme.primaryColor.withOpacity(0.3)
              : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Checkbox
              _buildCompletionCheckbox(context, isCompleted),
              const SizedBox(width: 16.0),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (habit.description.isNotEmpty && showDetails)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    if (showDetails) const SizedBox(height: 8.0),
                    if (showDetails) _buildHabitStats(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCheckbox(BuildContext context, bool isCompleted) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          border: Border.all(
            color: isCompleted
                ? Theme.of(context).primaryColor
                : Colors.grey,
            width: 2.0,
          ),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 16.0,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildHabitStats(BuildContext context) {
    return Row(
      children: [
        // Streak
        if (habit.streakCount > 0)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.orange.withOpacity(0.1),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${habit.streakCount} day${habit.streakCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
        // Reminder time
        if (habit.streakCount > 0) const SizedBox(width: 8.0),
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Colors.blue.withOpacity(0.1),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.blue,
                size: 16.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                habit.reminderTime,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
