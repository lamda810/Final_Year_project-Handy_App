import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/chatbot/chatbot_bloc.dart';
import '../../blocs/chatbot/chatbot_event.dart';
import '../../blocs/chatbot/chatbot_state.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../../core/routes/app_routes.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatbotBloc>().add(ResetChatbot());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatbotBloc, ChatbotState>(
              listener: (context, state) {
                if (state is ChatbotResponseReceived) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatbotInitial) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 80, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'How can I help you today?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          child: Text(
                            'Describe your problem, and I will find the right service and estimate the price for you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<Map<String, dynamic>> messages = [];
                if (state is ChatbotResponseReceived) {
                  messages = state.messages;
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (state is ChatbotLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] ?? '',
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
            if (!isUser && msg['detectedService'] != null) ...[
              const SizedBox(height: 12),
              _buildAISuggestionCard(msg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard(Map<String, dynamic> msg) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Service: ${msg['detectedService']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (msg['estimatedPrice'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Est. Price: Rs ${msg['estimatedPrice']['min']} - ${msg['estimatedPrice']['max']}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Booking screen with pre-filled info
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.createBooking, 
                    arguments: {
                      'category': msg['detectedService'],
                      'description': msg['text'],
                    }
                  );
                },
                child: const Text('Book This Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Describe your problem...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // Get user context from UserBloc if available
    String? city;
    String? area;
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      // Assuming user model has address or location info
      // city = userState.user.city; 
    }

    context.read<ChatbotBloc>().add(
      SendChatMessage(
        message: _messageController.text.trim(),
        city: city, // You can pull this from current location or selection
        area: area,
      ),
    );

    _messageController.clear();
  }
}
