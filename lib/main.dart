import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:habit_ai_companion/providers/chat_provider.dart';
import 'package:habit_ai_companion/providers/habit_provider.dart';
import 'package:habit_ai_companion/providers/timetable_provider.dart';
import 'package:habit_ai_companion/screens/home_screen.dart';
import 'package:habit_ai_companion/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/habit.dart';
import 'models/timetable_entry.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(TimetableEntryAdapter());

  // Open boxes
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<TimetableEntry>('timetable');
  await Hive.openBox('settings');

  // Initialize notification service
  await NotificationService().initialize();

  OpenAI.apiKey = 'sk-...p5oA';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Habit Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
