import 'package:equatable/equatable.dart';

/// Events for [ChatbotBloc].
abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();
  @override
  List<Object?> get props => [];
}

/// Send a message to the AI assistant.
class SendChatMessage extends ChatbotEvent {
  final String message;
  const SendChatMessage({required this.message});
  @override
  List<Object?> get props => [message];
}

/// Clear the conversation and start fresh.
class ResetChatbot extends ChatbotEvent {
  const ResetChatbot();
}
