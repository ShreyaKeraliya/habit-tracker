import 'package:flutter/material.dart';
import 'package:habit_ai_companion/screens/timetable_screen.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/timetable_entry_card.dart';
import 'chatbot_screen.dart';
import 'growth_screen.dart';
import 'habit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardPage(),
    const HabitScreen(),
    const TimetableScreen(),
    const GrowthScreen(),
    const ChatbotScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Growth',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh data
              await Future.delayed(const Duration(milliseconds: 500));
              if (context.mounted) {
                Provider.of<HabitProvider>(context, listen: false).notifyListeners();
                Provider.of<TimetableProvider>(context, listen: false).notifyListeners();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  _buildGreeting(),
                  const SizedBox(height: 24.0),
                  
                  // Today's progress
                  _buildTodayProgress(),
                  const SizedBox(height: 24.0),
                  
                  // Habits due today
                  _buildHabitsSection(context),
                  const SizedBox(height: 24.0),
                  
                  // Upcoming schedule
                  _buildScheduleSection(context),
                  const SizedBox(height: 16.0),
                  
                  // Ask assistant button
                  _buildAssistantButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGreeting() {
    final now = DateTime.now();
    String greeting = '';
    
    if (now.hour < 12) {
      greeting = 'Good morning';
    } else if (now.hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _getFormattedDate(),
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
  
  Widget _buildTodayProgress() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        var h = 0;
        final todayHabits = habits.where((h) => 
          h.reminderDays.contains(DateTime.now().weekday)
        ).toList();
        
        if (todayHabits.isEmpty) {
          return const SizedBox.shrink();
        }
        
        int completed = todayHabits.where((h) => h.isCompletedToday()).length;
        double progress = todayHabits.isEmpty ? 0 : completed / todayHabits.length;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Progress',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12.0,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Lighter neutral
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary, // Contrasting accent
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Text(
                  '$completed/${todayHabits.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildHabitsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        final todayHabits = habits.where((h) => 
          h!.reminderDays.contains(DateTime.now().weekday)
        ).toList();
        
        if (todayHabits.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Habits',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HabitScreen(),
                        ),
                      );
                    },
                    child: const Text('Add Habits'),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48.0,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No habits scheduled for today',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HabitScreen(),
                              ),
                            );
                          },
                          child: const Text('Add a habit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Habits',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            for (var habit in todayHabits.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: HabitCard(
                  habit: habit,
                  onToggle: () {
                    habitProvider.toggleHabitCompletion(habit.id);
                  },
                ),
              ),
            if (todayHabits.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View ${todayHabits.length - 3} more habits',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildScheduleSection(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, timetableProvider, child) {
        final upcomingEntries = timetableProvider.getUpcomingEntries();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Schedule',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimetableScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (upcomingEntries.isEmpty)
              Card(
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48.0,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'No upcoming activities',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TimetableScreen(),
                              ),
                            );
                          },
                          child: const Text('Plan your day'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              for (var entry in upcomingEntries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TimetableEntryCard(
                    entry: entry,
                    onToggle: () {
                      timetableProvider.toggleEntryCompletion(entry.id);
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
  
  Widget _buildAssistantButton(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assistant,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ask the Assistant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Get suggestions, improve your habits, and optimize your schedule',
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
