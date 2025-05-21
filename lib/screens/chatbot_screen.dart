import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/timetable_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant',),
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'suggestions',
                child: const Text('Get Habit Suggestions'),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<ChatProvider>(context, listen: false)
                        .askForSuggestions();
                  });
                },
              ),
              PopupMenuItem(
                value: 'schedule',
                child: const Text('Optimize Schedule'),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<ChatProvider>(context, listen: false)
                        .askForScheduleOptimization();
                  });
                },
              ),
              PopupMenuItem(
                value: 'motivation',
                child: const Text('Get Motivation'),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<ChatProvider>(context, listen: false)
                        .askForMotivation();
                  });
                },
              ),
              PopupMenuItem(
                value: 'clear',
                child: const Text('Clear Chat'),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<ChatProvider>(context, listen: false)
                        .clearChat();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat stats banner
          _buildStatsBanner(),
          // Chat messages
          Expanded(
            child: _buildMessageList(),
          ),
          // AI typing indicator
          _buildTypingIndicator(),
          // Input field
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Consumer2<HabitProvider, TimetableProvider>(
      builder: (context, habitProvider, timetableProvider, child) {
        final completionRate = habitProvider.getAverageCompletionRate();
        final upcomingCount = timetableProvider.getUpcomingEntries().length;
        final habitCount = habitProvider.habits.length;

        if (habitCount == 0 && upcomingCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (habitCount > 0)
                Column(
                  children: [
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const Text(
                      'Habit Completion',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              if (upcomingCount > 0)
                Column(
                  children: [
                    Text(
                      '$upcomingCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const Text(
                      'Upcoming Events',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;

        // Scroll to bottom when messages change
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Start chatting with your assistant!',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ChatBubble(
                message: message,
                showTime: _shouldShowTime(messages, index),
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldShowTime(List<ChatMessage> messages, int index) {
    // Show time for first message
    if (index == 0) return true;
    
    // Show time if messages are from different users
    if (messages[index].isUser != messages[index - 1].isUser) return true;
    
    // Show time if messages are more than 5 minutes apart
    final timeDifference = messages[index].timestamp.difference(
      messages[index - 1].timestamp
    ).inMinutes;
    
    return timeDifference >= 5;
  }

  Widget _buildTypingIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.isTyping) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(width: 3.0),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(width: 3.0),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Assistant is typing...',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.help_outline,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                _showSuggestedQuestions();
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Ask a question...',
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _isComposing
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              onPressed: _isComposing
                  ? () => _handleSubmitted(_textController.text)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    
    Provider.of<ChatProvider>(context, listen: false).sendMessage(text);
  }

  void _showSuggestedQuestions() {
    final questions = [
      'How can I improve my habit consistency?',
      'What\'s the best time of day for my habits?',
      'How can I optimize my schedule?',
      'Can you suggest some good habits to add?',
      'I keep forgetting my habits. Any tips?',
      'Help me organize my day better',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggested Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: questions.map((question) {
                    return ActionChip(
                      label: Text(question),
                      onPressed: () {
                        Navigator.pop(context);
                        _textController.text = question;
                        setState(() {
                          _isComposing = true;
                        });
                        // Focus the text field
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
