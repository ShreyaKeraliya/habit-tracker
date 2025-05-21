import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/chat_message.dart';
import '../services/ai_suggestion_service.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final AiSuggestionService _aiService = AiSuggestionService();
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Add welcome message
    if (_messages.isEmpty) {
      _addBotMessage(
        "Hello! I'm your habit tracking assistant. I can help you plan your schedule, "
        "suggest improvements to your habits, and answer questions. How can I help you today?",
      );
    }
  }

  void _addBotMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: false,
    );
    _messages.add(message);
    notifyListeners();
    
    // Save the message to local storage if needed
    _saveMessagesToStorage();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
    );
    _messages.add(userMessage);
    notifyListeners();
    
    // Save the message to local storage
    _saveMessagesToStorage();
    
    // Set typing indicator
    _isTyping = true;
    notifyListeners();
    
    // Generate response
    try {
      final response = await _aiService.generateResponse(text, _messages);
      
      // Add bot message
      final botMessage = ChatMessage(
        text: response,
        isUser: false,
      );
      _messages.add(botMessage);
      _saveMessagesToStorage();
    } catch (e) {
      // Handle error
      final errorMessage = ChatMessage(
        text: "I'm sorry, I couldn't process your request. Please try again later.",
        isUser: false,
      );
      _messages.add(errorMessage);
      _saveMessagesToStorage();
    } finally {
      // Remove typing indicator
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> askForSuggestions() async {
    const question = "Can you give me suggestions to improve my habits?";
    await sendMessage(question);
  }

  Future<void> askForScheduleOptimization() async {
    const question = "How can I optimize my daily schedule?";
    await sendMessage(question);
  }

  Future<void> askForMotivation() async {
    const question = "I'm feeling unmotivated to stick to my habits. Any advice?";
    await sendMessage(question);
  }

  void clearChat() {
    _messages.clear();
    _initialize();
    notifyListeners();
    
    // Clear chat history from storage
    _saveMessagesToStorage();
  }
  
  Future<void> _saveMessagesToStorage() async {
    try {
      final box = Hive.box('settings');
      final messagesJson = _messages.map((msg) => msg.toMap()).toList();
      await box.put('chat_history', messagesJson);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }
  
  Future<void> _loadMessagesFromStorage() async {
    try {
      final box = Hive.box('settings');
      final messagesJson = box.get('chat_history');
      if (messagesJson != null) {
        _messages.clear();
        for (var json in messagesJson) {
          _messages.add(ChatMessage.fromMap(json));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }
}
