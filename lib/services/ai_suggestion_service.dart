
import 'package:flutter/foundation.dart';
import 'package:habit_ai_companion/services/timetable_service.dart';

import '../models/chat_message.dart';
import '../models/habit.dart';
import 'habit_service.dart';

class AiSuggestionService {
  final HabitService _habitService = HabitService();
  final TimetableService _timetableService = TimetableService();

  Future<String> generateResponse(String userMessage, List<ChatMessage> context) async {
    try {
      // Convert user message to lowercase for easier pattern matching
      final String messageLC = userMessage.toLowerCase();
      
      // Check for habit-related queries
      if (messageLC.contains('habit') || 
          messageLC.contains('track') || 
          messageLC.contains('progress')) {
        return _generateHabitSuggestions();
      }
      
      // Check for schedule-related queries
      else if (messageLC.contains('schedule') || 
               messageLC.contains('timetable') || 
               messageLC.contains('plan') ||
               messageLC.contains('time')) {
        return _generateScheduleSuggestions();
      }
      
      // Check for motivation or assistance
      else if (messageLC.contains('motivat') || 
               messageLC.contains('help') || 
               messageLC.contains('difficult') ||
               messageLC.contains('struggle') ||
               messageLC.contains('improve')) {
        return _generateMotivationalSuggestions();
      }
      
      // Check for greeting
      else if (messageLC.contains('hi') || 
               messageLC.contains('hello') || 
               messageLC.contains('hey')) {
        return "Hello! I'm your habit tracking assistant. How can I help you today?";
      }
      
      // Check for thanks
      else if (messageLC.contains('thank') || 
               messageLC.contains('thanks')) {
        return "You're welcome! Let me know if you need any more help with your habits or schedule.";
      }
      
      // Default response
      else {
        return _generateGeneralSuggestions();
      }
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      return "I apologize, but I'm having trouble processing your request right now. What else can I help you with?";
    }
  }
  
  String _generateHabitSuggestions() {
    // Get habit data
    final habits = _habitService.getAllHabits();
    final needAttention = _habitService.getHabitsThatNeedAttention();
    final topHabits = _habitService.getTopHabitsByStreak(3);
    final completionRate = _habitService.getWeeklyCompletionRate();
    final completedToday = _habitService.getHabitsCompletedToday();
    final notCompletedToday = _habitService.getHabitsNotCompletedToday();
    
    // Build response
    String response = '';
    
    // If no habits
    if (habits.isEmpty) {
      return "I notice you haven't added any habits to track yet. "
          "Adding habits is a great way to build consistency in your daily routine. "
          "Would you like to add a habit now? Some ideas include drinking water, "
          "reading, meditating, or exercising.";
    }
    
    // Comment on completion rate
    response += "Looking at your habits, your weekly completion rate is ${(completionRate * 100).toStringAsFixed(0)}%. ";
    
    if (completionRate > 0.8) {
      response += "That's excellent! You're doing a great job maintaining your habits. ";
    } else if (completionRate > 0.5) {
      response += "That's pretty good! There's still room for improvement. ";
    } else {
      response += "It looks like you're having some challenges with consistency. "
          "Let's see how we can improve this. ";
    }
    
    // Comment on today's progress
    response += "\n\nToday, you've completed ${completedToday.length} out of ${completedToday.length + notCompletedToday.length} habits. ";
    
    if (notCompletedToday.isNotEmpty) {
      response += "You still need to complete: ";
      for (int i = 0; i < notCompletedToday.length; i++) {
        if (i > 0) response += ", ";
        response += notCompletedToday[i].name;
      }
      response += ". ";
    }
    
    // Suggest improvements
    if (needAttention.isNotEmpty) {
      response += "\n\nI notice you're having trouble with consistency in these habits: ";
      for (int i = 0; i < needAttention.length; i++) {
        if (i > 0) response += ", ";
        response += needAttention[i].name;
      }
      
      response += ". Here are some suggestions:\n";
      response += "• Try pairing these habits with something you already do consistently\n";
      response += "• Schedule them for your most productive time of day\n";
      response += "• Break them down into smaller, more manageable tasks\n";
      response += "• Set reminders at specific times";
    }
    
    // Celebrate strengths
    if (topHabits.isNotEmpty) {
      response += "\n\nYou're doing great with these habits: ";
      for (int i = 0; i < topHabits.length; i++) {
        if (i > 0) response += ", ";
        response += "${topHabits[i].name} (${topHabits[i].streakCount} day streak)";
      }
      response += ". Keep up the good work!";
    }
    
    return response;
  }
  
  String _generateScheduleSuggestions() {
    // Get schedule data
    final allEntries = _timetableService.getAllEntries();
    final currentEntries = _timetableService.getCurrentEntries();
    final upcomingEntries = _timetableService.getUpcomingEntries(3); // Next 3 hours
    
    // Get today's date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get free time slots for today
    final freeSlots = _timetableService.getFreeTimeSlots(today);
    
    // Build response
    String response = '';
    
    // If no schedule entries
    if (allEntries.isEmpty) {
      return "I notice you haven't added any activities to your schedule yet. "
          "Planning your day can help you make time for your habits and important tasks. "
          "Would you like to add something to your schedule now?";
    }
    
    // Current activities
    if (currentEntries.isNotEmpty) {
      response += "Right now, you should be: ";
      for (int i = 0; i < currentEntries.length; i++) {
        if (i > 0) response += ", ";
        response += currentEntries[i].title;
      }
      response += ". ";
    } else {
      response += "You don't have any scheduled activities right now. ";
    }
    
    // Upcoming activities
    if (upcomingEntries.isNotEmpty) {
      response += "\n\nComing up in the next few hours: ";
      for (int i = 0; i < upcomingEntries.length; i++) {
        final entry = upcomingEntries[i];
        final startTime = "${entry.startTime.hour.toString().padLeft(2, '0')}:${entry.startTime.minute.toString().padLeft(2, '0')}";
        
        if (i > 0) response += ", ";
        response += "${entry.title} at $startTime";
      }
      response += ". ";
    }
    
    // Free time slots
    if (freeSlots.isNotEmpty) {
      response += "\n\nYou have free time available today: ";
      for (int i = 0; i < freeSlots.length && i < 3; i++) { // Show up to 3 free slots
        final slot = freeSlots[i];
        final startTime = "${slot['start']!.hour.toString().padLeft(2, '0')}:${slot['start']!.minute.toString().padLeft(2, '0')}";
        final endTime = "${slot['end']!.hour.toString().padLeft(2, '0')}:${slot['end']!.minute.toString().padLeft(2, '0')}";
        final duration = slot['end']!.difference(slot['start']!).inMinutes;
        
        if (i > 0) response += ", ";
        response += "$startTime-$endTime (${duration}min)";
      }
      
      // Add suggestions for free time
      response += "\n\nSuggestions for your free time:";
      response += "\n• Complete any remaining habits for today";
      response += "\n• Take short breaks between focused work sessions";
      response += "\n• Reserve time for self-care activities";
      response += "\n• Plan buffer time between activities";
    }
    
    // Schedule optimization tips
    response += "\n\nGeneral schedule tips:";
    response += "\n• Group similar activities together";
    response += "\n• Schedule your most important tasks during your peak energy hours";
    response += "\n• Include breaks to prevent burnout";
    response += "\n• Don't overschedule—allow flex time for unexpected events";
    
    return response;
  }
  
  String _generateMotivationalSuggestions() {
    final suggestions = [
      "Remember that building habits is a journey, not a destination. Small progress is still progress!",
      
      "When you're struggling with motivation, try the '2-minute rule': commit to just 2 minutes of an activity. Often, getting started is the hardest part, and you'll find yourself continuing beyond those initial minutes.",
      
      "Your habits shape your identity. Each time you complete a habit, you're becoming the type of person who does that activity regularly.",
      
      "If you've missed a few days, don't worry about breaking the chain. Focus on getting back on track today—consistency matters more than perfection.",
      
      "Try habit stacking: Link a new habit you're trying to build with an existing habit you already do consistently.",
      
      "Make your habits obvious, attractive, easy, and satisfying—these are the four laws of behavior change that can help you build better habits.",
      
      "If you're struggling with a particular habit, try making it easier or breaking it down into smaller steps.",
      
      "Reward yourself immediately after completing difficult habits to create a positive feedback loop in your brain.",
      
      "Environment often matters more than motivation. Design your space to make good habits obvious and bad habits invisible.",
      
      "Track your progress to stay motivated. Seeing how far you've come can be incredibly encouraging during difficult times."
    ];
    
    // Choose 3-4 random suggestions
    suggestions.shuffle();
    final selectedSuggestions = suggestions.take(3).toList();
    
    String response = "Here are some thoughts to help you stay motivated:\n\n";
    
    for (final suggestion in selectedSuggestions) {
      response += "• $suggestion\n\n";
    }
    
    response += "Remember that building good habits isn't about being perfect; it's about making small improvements consistently. What specific habit are you finding most challenging right now?";
    
    return response;
  }
  
  String _generateGeneralSuggestions() {
    return "I'm here to help with your habits and schedule. Here are some things I can do:\n\n"
           "• Give you suggestions about your habits\n"
           "• Help optimize your schedule\n"
           "• Provide motivation when you're struggling\n"
           "• Answer questions about habit formation\n\n"
           "What would you like help with today?";
  }
  
  // Generate suggestions specifically for habits that need attention
  String generateSuggestionsForHabit(Habit habit) {
    final completionRate = habit.getCompletionRateLastWeek();
    String suggestion = "About your habit \"${habit.name}\": ";
    
    if (completionRate < 0.3) {
      suggestion += "I notice you're having difficulty maintaining this habit consistently. "
                   "Consider these approaches:\n\n"
                   "• Make it easier: Reduce the scope to make it more doable\n"
                   "• Better timing: Schedule it when you have more energy\n"
                   "• Clear triggers: Link it to an existing habit you already do\n"
                   "• Accountability: Share your goal with someone supportive";
    } else if (completionRate < 0.7) {
      suggestion += "You're doing this habit sometimes, but there's room for improvement. "
                   "Here are some ideas:\n\n"
                   "• Set a specific time each day for this habit\n"
                   "• Create a visual reminder in your environment\n"
                   "• Track your streaks to build momentum\n"
                   "• Reflect on the benefits you experience when you do complete it";
    } else {
      suggestion += "You're doing well with this habit! To maintain your success:\n\n"
                   "• Celebrate your consistency\n"
                   "• Consider gradually increasing the challenge\n"
                   "• Use this success to build confidence for other habits\n"
                   "• Reflect on what's working well and apply those lessons elsewhere";
    }
    
    return suggestion;
  }
}
