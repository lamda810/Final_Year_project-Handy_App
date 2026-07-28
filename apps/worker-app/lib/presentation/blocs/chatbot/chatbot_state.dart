import 'package:equatable/equatable.dart';

/// States for [ChatbotBloc].
abstract class ChatbotState extends Equatable {
  const ChatbotState();
  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial();
}

class ChatbotLoading extends ChatbotState {
  const ChatbotLoading();
}

class ChatbotResponseReceived extends ChatbotState {
  final List<Map<String, dynamic>> messages;
  const ChatbotResponseReceived(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatbotError extends ChatbotState {
  final String message;
  const ChatbotError(this.message);
  @override
  List<Object?> get props => [message];
}
