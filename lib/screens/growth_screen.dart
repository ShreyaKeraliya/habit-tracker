import 'package:flutter/material.dart';
import 'package:habit_ai_companion/models/timetable_entry.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import '../providers/timetable_provider.dart';
import '../models/habit.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  String selectedTab = "Weekly";
  final List<String> tabs = ["Daily", "Weekly", "Monthly"];

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final timetableProvider = Provider.of<TimetableProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Filtered habits & events
    final filteredHabits = _filterHabits(habitProvider.habits);
    final filteredEvents = _filterEvents(timetableProvider.entries.cast<TimetableEntry>());

    final completedHabits = filteredHabits.where((h) => h!.isCompletedToday()).length;
    final pendingHabits = filteredHabits.length - completedHabits;
    final habitCompletionRate = filteredHabits.isEmpty ? 0 : completedHabits / filteredHabits.length;

    final now = DateTime.now();
    int completedTasks = 0;
    int pendingTasks = 0;
    int notCompletedTasks = 0;

    for (var event in filteredEvents) {
      if (event.startTime.isBefore(now) && event.isCompleted) {
        completedTasks++;
      } else if (event.startTime.isAfter(now)) {
        pendingTasks++;
      } else if (event.startTime.isBefore(now) && !event.isCompleted) {
        notCompletedTasks++;
      }
    }

    final totalCompleted = completedHabits + completedTasks;
    final totalPending = pendingHabits + pendingTasks;
    final combinedCompletionRate = ((habitCompletionRate + (completedTasks / (filteredEvents.isEmpty ? 1 : filteredEvents.length))) / 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Growth Overview"),
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCard(totalCompleted, totalPending, combinedCompletionRate, colorScheme, textTheme),
            const SizedBox(height: 16),
            _buildTabBar(colorScheme),
            const SizedBox(height: 20),
            Expanded(child: _buildBarChart(filteredHabits, filteredEvents, colorScheme, textTheme)),
          ],
        ),
      ),
    );
  }

  List<Habit> _filterHabits(List<Habit> habits) {
    final now = DateTime.now();
    return habits.where((habit) {
      return habit.completionDates.any((date) {
        return _isDateInSelectedRange(date, now);
      });
    }).toList();
  }

  List<TimetableEntry> _filterEvents(List<TimetableEntry> events) {
    final now = DateTime.now();
    return events.where((event) => _isDateInSelectedRange(event.startTime, now)).toList();
  }

  bool _isDateInSelectedRange(DateTime date, DateTime now) {
    switch (selectedTab) {
      case "Daily":
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case "Weekly":
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case "Monthly":
        return date.year == now.year && date.month == now.month;
      default:
        return false;
    }
  }

  Widget _buildSummaryCard(int completed, int pending, double completionRate, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline),
      ),
      elevation: 4,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "$selectedTab Progress",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressTile("Completed", "$completed", textTheme, colorScheme),
                _buildProgressTile("Pending", "$pending", textTheme, colorScheme),
                _buildProgressTile("Completion", "${(completionRate * 100).toStringAsFixed(0)}%", textTheme, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTile(String title, String value, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(value, style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tabs.map((tab) {
        final isSelected = tab == selectedTab;
        return GestureDetector(
          onTap: () => setState(() => selectedTab = tab),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary),
              boxShadow: isSelected
                  ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Text(
              tab,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(List<Habit> habits, List<TimetableEntry> events, ColorScheme colorScheme, TextTheme textTheme) {
    final counts = List.filled(7, 0);

    for (var habit in habits) {
      for (var date in habit.completionDates) {
        if (_isDateInSelectedRange(date, DateTime.now())) {
          final weekday = (date.weekday - 1) % 7;
          counts[weekday]++;
        }
      }
    }

    for (var event in events) {
      if (_isDateInSelectedRange(event.startTime, DateTime.now())) {
        final weekday = (event.startTime.weekday - 1) % 7;
        counts[weekday]++;
      }
    }

    final maxY = (counts.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onBackground),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[value.toInt()],
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground),
                  ),
                );
              },
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              color: colorScheme.primary,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ]);
        }),
      ),
    );
  }
}
