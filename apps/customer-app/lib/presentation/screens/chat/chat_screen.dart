import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';

/// Chat screen for customer to communicate with worker
class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String workerName;
  final String workerPhone;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.workerName,
    required this.workerPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = GetIt.instance<DioClient>().dio;
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
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
      debugPrint('[Chat] Loading messages for booking: ${widget.bookingId}');
      final response = await _dio.get(
        ApiEndpoints.bookingMessages(widget.bookingId),
      );
      final rows = (response.data['data'] as List<dynamic>? ?? []);

      debugPrint('[Chat] Fetched ${rows.length} messages from server');

      final fetched = <ChatMessage>[];
      for (final row in rows) {
        fetched.add(
          ChatMessage(
            id: row['_id'] ?? '',
            text: row['message'] ?? '',
            isFromWorker: row['senderType'] == 'WORKER',
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
          '[Chat] New messages detected, updating UI (existing: ${existingIds.length}, fetched: ${fetchedIds.length})',
        );
        // Keep any pending temp messages and merge with server data
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
      debugPrint('[Chat] Error loading messages: $e');
      if (mounted && _isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    // Optimistic add
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      text: text,
      isFromWorker: false,
      timestamp: DateTime.now(),
    );

    setState(() => _messages.add(tempMessage));
    _scrollToBottom();

    try {
      debugPrint(
        '[Chat] Sending message to booking ${widget.bookingId}: "${text.length > 50 ? text.substring(0, 50) : text}"',
      );
      final response = await _dio.post(
        ApiEndpoints.bookingMessages(widget.bookingId),
        data: {'message': text},
      );
      final row = response.data['data'] as Map<String, dynamic>? ?? {};
      debugPrint('[Chat] Message sent successfully, id: ${row['_id']}');

      // Replace temp message with real one
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: row['_id'] ?? tempId,
              text: text,
              isFromWorker: false,
              timestamp: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[Chat] Failed to send message: $e');
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
    } finally {
      if (mounted) setState(() => _isSending = false);
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

  void _callWorker() async {
    final phone = widget.workerPhone;
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker phone number not available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            _buildQuickReplies(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.workerName.isNotEmpty ? widget.workerName[0] : 'W',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workerName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: AppColors.primary),
          onPressed: _callWorker,
          tooltip: 'Call Worker',
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildMessagesList() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.\nStart a conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDate =
            index == 0 ||
            !_isSameDay(_messages[index - 1].timestamp, message.timestamp);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.timestamp),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    String text;

    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = !message.isFromWorker;
    final localTs = message.timestamp.toLocal();
    final time =
        '${localTs.hour.toString().padLeft(2, '0')}:${localTs.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: isMe ? Colors.white : colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 14, color: Colors.white),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      'Where are you?',
      'I\'m waiting',
      'Please hurry',
      'Take your time',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickReplies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ActionChip(
                label: Text(
                  reply,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                onPressed: () => _sendQuickMessage(reply),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              onPressed: () {
                // TODO: Implement attachment picker:
                //  1. Show bottom sheet with Camera / Gallery / File options
                //  2. Use image_picker or file_picker packages
                //  3. Upload to backend storage, then send URL as message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Attachments are not available in this version',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final bool isFromWorker;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromWorker,
    required this.timestamp,
  });
}
