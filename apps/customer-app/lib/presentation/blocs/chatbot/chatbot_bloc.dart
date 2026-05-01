import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/matching_repository.dart';
import 'chatbot_event.dart';
import 'chatbot_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final MatchingRepository _matchingRepository;
  final List<Map<String, dynamic>> _messages = [];

  ChatbotBloc({required MatchingRepository matchingRepository})
      : _matchingRepository = matchingRepository,
        super(ChatbotInitial()) {
    on<SendChatMessage>(_onSendChatMessage);
    on<ResetChatbot>(_onResetChatbot);
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<ChatbotState> emit,
  ) async {
    // Add user message to list
    _messages.add({
      'isUser': true,
      'text': event.message,
      'timestamp': DateTime.now(),
    });

    emit(ChatbotResponseReceived(List.from(_messages)));
    emit(ChatbotLoading());

    try {
      final response = await _matchingRepository.askAiAssistant(
        message: event.message,
        city: event.city,
        area: event.area,
      );

      // Add AI response to list
      _messages.add({
        'isUser': false,
        'text': response['message'],
        'detectedService': response['detectedService'],
        'estimatedPrice': response['estimatedPrice'],
        'timestamp': DateTime.now(),
      });

      emit(ChatbotResponseReceived(List.from(_messages)));
    } catch (e) {
      emit(ChatbotError(e.toString()));
      // Fallback state to keep existing messages visible
      emit(ChatbotResponseReceived(List.from(_messages)));
    }
  }

  void _onResetChatbot(ResetChatbot event, Emitter<ChatbotState> emit) {
    _messages.clear();
    emit(ChatbotInitial());
  }
}
