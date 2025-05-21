import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timetable_entry.dart';

class TimetableEntryCard extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const TimetableEntryCard({
    Key? key,
    required this.entry,
    required this.onToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHappeningNow = entry.isHappeningNow();
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isHappeningNow
              ? _hexToColor(entry.color).withOpacity(0.5)
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              _buildTimeColumn(context),
              const SizedBox(width: 16.0),
              
              // Content column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        decoration: entry.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: entry.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (entry.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          entry.description,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                            decoration: entry.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8.0),
                    _buildEntryMetadata(context),
                  ],
                ),
              ),
              
              // Completion checkbox (only for reminder entries)
              if (entry.isReminder) 
                _buildCompletionCheckbox(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context) {
    final startHour = entry.startTime.hour.toString().padLeft(2, '0');
    final startMinute = entry.startTime.minute.toString().padLeft(2, '0');
    final endHour = entry.endTime.hour.toString().padLeft(2, '0');
    final endMinute = entry.endTime.minute.toString().padLeft(2, '0');
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0, 
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: _hexToColor(entry.color),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(4.0),
            ),
          ),
          child: Text(
            '$startHour:$startMinute',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0, 
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: _hexToColor(entry.color).withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4.0),
              bottomRight: Radius.circular(4.0),
            ),
          ),
          child: Text(
            '$endHour:$endMinute',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryMetadata(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        // Duration
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: _hexToColor(entry.color).withOpacity(0.1),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timelapse,
                color: _hexToColor(entry.color),
                size: 16.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                _formatDuration(entry.getDuration()),
                style: TextStyle(
                  fontSize: 12.0,
                  color: _hexToColor(entry.color),
                ),
              ),
            ],
          ),
        ),
        
        // Repeat info
        if (entry.repeatDays.isNotEmpty)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.grey.withOpacity(0.1),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.repeat,
                  color: Colors.grey,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  _getRepeatDaysText(),
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
        // Reminder indicator
        if (entry.isReminder)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.orange.withOpacity(0.1),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 16.0,
                ),
                SizedBox(width: 4.0),
                Text(
                  'Reminder',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionCheckbox(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: entry.isCompleted
                ? _hexToColor(entry.color)
                : Colors.transparent,
            border: Border.all(
              color: entry.isCompleted
                  ? _hexToColor(entry.color)
                  : Colors.grey,
              width: 2.0,
            ),
          ),
          child: entry.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16.0,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr${hours != 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  String _getRepeatDaysText() {
    if (entry.repeatDays.length == 7) {
      return 'Daily';
    } else if (entry.repeatDays.length == 5 && 
               entry.repeatDays.contains(1) && 
               entry.repeatDays.contains(2) && 
               entry.repeatDays.contains(3) && 
               entry.repeatDays.contains(4) && 
               entry.repeatDays.contains(5)) {
      return 'Weekdays';
    } else if (entry.repeatDays.length == 2 && 
               entry.repeatDays.contains(6) && 
               entry.repeatDays.contains(7)) {
      return 'Weekends';
    } else {
      final dayLabels = entry.repeatDays.map((day) {
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
      }).join('');
      
      return dayLabels;
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
