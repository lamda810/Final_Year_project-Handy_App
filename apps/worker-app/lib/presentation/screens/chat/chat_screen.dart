import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../injection_container.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String customerName;
  final String customerPhone;
  final String? bookingNumber;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    this.bookingNumber,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = sl<DioClient>().dio;
  final List<_ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    // Poll for new messages every 5s
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isLoading) _loadMessages();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Reload messages when app comes back to foreground
      _loadMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      debugPrint(
        '[WorkerChat] Loading messages for booking: ${widget.bookingId}',
      );
      final response = await _dio.get(
        ApiEndpoints.bookingMessages(widget.bookingId),
      );
      final rows = (response.data['data'] as List<dynamic>? ?? []);

      debugPrint('[WorkerChat] Fetched ${rows.length} messages from server');

      final fetched = <_ChatMessage>[];
      for (final row in rows) {
        fetched.add(
          _ChatMessage(
            id: row['_id'] ?? '',
            text: row['message'] ?? '',
            isMe: row['senderType'] == 'WORKER',
            timestamp:
                DateTime.tryParse(row['createdAt'] ?? '') ?? DateTime.now(),
          ),
        );
      }

      // Smart merge: only update if there are new messages (avoids flicker)
      final existingIds = _messages
          .where((m) => !m.id.startsWith('temp_'))
          .map((m) => m.id)
          .toSet();
      final fetchedIds = fetched.map((m) => m.id).toSet();
      if (!existingIds.containsAll(fetchedIds) ||
          existingIds.length != fetchedIds.length) {
        debugPrint(
          '[WorkerChat] New messages detected, updating UI (existing: ${existingIds.length}, fetched: ${fetchedIds.length})',
        );
        final temps = _messages.where((m) => m.id.startsWith('temp_')).toList();
        _messages.clear();
        _messages.addAll(fetched);
        _messages.addAll(temps);
        if (mounted) {
          setState(() {});
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('[WorkerChat] Error loading messages: $e');
      if (_isLoading) _error = 'Chat is not available at the moment';
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Optimistic add
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = _ChatMessage(
      id: tempId,
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() => _messages.add(tempMessage));
    _scrollToBottom();

    try {
      debugPrint(
        '[WorkerChat] Sending message to booking ${widget.bookingId}: "${text.length > 50 ? text.substring(0, 50) : text}"',
      );
      final response = await _dio.post(
        ApiEndpoints.bookingMessages(widget.bookingId),
        data: {'message': text},
      );
      final row = response.data['data'] as Map<String, dynamic>? ?? {};
      debugPrint('[WorkerChat] Message sent successfully, id: ${row['_id']}');

      // Replace temp message with real one (so polling dedup works)
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = _ChatMessage(
              id: row['_id'] ?? tempId,
              text: text,
              isMe: true,
              timestamp:
                  DateTime.tryParse(row['createdAt'] ?? '') ?? DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[WorkerChat] Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontSize: 16)),
            Text(
              'Booking: ${widget.bookingNumber ?? widget.bookingId}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              launchUrl(Uri.parse('tel:${widget.customerPhone}'));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Error: $_error'),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
          ),

          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start a conversation with ${widget.customerName}',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe
              ? AppColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe
                    ? AppColors.textOnPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: message.isMe
                    ? AppColors.textOnPrimary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: AppColors.textOnPrimary,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}
