import 'package:dart_openai/dart_openai.dart';

class AIService {
  Future<Object> generateResponse(
      String message,
      List habits,
      List todayHabits,
      List overdueHabits,
      double completionRate,
      List upcomingEvents,
      List currentEvents,
      ) async {
    String context = '''
User Message: $message
Today's Habits: ${todayHabits.join(', ')}
Overdue Habits: ${overdueHabits.join(', ')}
Weekly Completion Rate: ${completionRate.toStringAsFixed(2)}%
Upcoming Events: ${upcomingEvents.join(', ')}
Current Events: ${currentEvents.join(', ')}
    ''';

    final chat = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        // OpenAIChatCompletionMessageParam(
        //   role: OpenAIChatMessageRole.system,
        //   content: "You're a helpful productivity assistant.",
        // ),
        // OpenAIChatCompletionMessageParam(
        //   role: OpenAIChatMessageRole.user,
        //   content: context,
        // ),
      ],
    );

    return chat.choices.first.message.content ?? "No response.";
  }

  String generateHabitSuggestion(List habits, List overdue, double rate) {
    if (habits.isEmpty) {
      return "You don't have any habits tracked yet. Start adding some!";
    }
    if (rate < 50) {
      return "Try focusing on smaller, more achievable habits to build momentum!";
    }
    if (overdue.isNotEmpty) {
      return "You're falling behind on some habits: ${overdue.join(', ')}. Try to complete them soon!";
    }
    return "Great job! You're staying consistent with your habits.";
  }

  String generateTimetableSuggestion(List upcoming, List current) {
    if (current.isEmpty) {
      return "You have free time right now. Consider using it for something productive!";
    }
    if (upcoming.length > 5) {
      return "Your upcoming schedule looks packed. Consider rescheduling or prioritizing tasks.";
    }
    return "Your timetable looks balanced. Keep it up!";
  }

  String generateWelcomeMessage(List today, List overdue, List upcoming) {
    return '''
Good day! Here's your quick summary:
- Today's Habits: ${today.length}
- Overdue Habits: ${overdue.length}
- Upcoming Events: ${upcoming.length}

Let me know how I can assist you today!
''';
  }
}
