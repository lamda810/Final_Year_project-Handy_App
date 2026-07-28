import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_mapper.dart';
import '../../../domain/repositories/matching_repository.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

/// Drives the worker-facing AI assistant: keeps the running conversation
/// and forwards each turn (with recent history) to the matching-service
/// chatbot endpoint.
class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final MatchingRepository _matchingRepo;
  final List<Map<String, dynamic>> _messages = [];

  ChatbotBloc({required MatchingRepository matchingRepository})
    : _matchingRepo = matchingRepository,
      super(const ChatbotInitial()) {
    on<SendChatMessage>(_onSendChatMessage);
    on<ResetChatbot>(_onResetChatbot);
  }

  List<Map<String, String>> _historyForApi() {
    // Last 10 turns is enough context and keeps the request small.
    final recent = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;
    return recent
        .map(
          (m) => {
            'role': (m['isUser'] as bool) ? 'user' : 'assistant',
            'content': (m['text'] ?? '').toString(),
          },
        )
        .where((m) => m['content']!.isNotEmpty)
        .toList();
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatbotState> emit,
  ) async {
    final historyForApi = _historyForApi();

    _messages.add({
      'isUser': true,
      'text': event.message,
      'timestamp': DateTime.now(),
    });
    emit(ChatbotResponseReceived(List.from(_messages)));
    emit(const ChatbotLoading());

    try {
      final response = await _matchingRepo.askAiAssistant(
        message: event.message,
        conversationHistory: historyForApi,
      );

      _messages.add({
        'isUser': false,
        'text': response['message'],
        'timestamp': DateTime.now(),
      });
      emit(ChatbotResponseReceived(List.from(_messages)));
    } catch (e) {
      emit(ChatbotError(ErrorMapper.toUserMessage(e)));
      // Fallback state to keep existing messages visible
      emit(ChatbotResponseReceived(List.from(_messages)));
    }
  }

  void _onResetChatbot(ResetChatbot event, Emitter<ChatbotState> emit) {
    _messages.clear();
    emit(const ChatbotInitial());
  }
}
