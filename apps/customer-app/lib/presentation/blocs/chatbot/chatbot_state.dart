import 'package:equatable/equatable.dart';

abstract class ChatbotState extends Equatable {
  const ChatbotState();

  @override
  List<Object?> get props => [];
}

class ChatbotInitial extends ChatbotState {}

class ChatbotLoading extends ChatbotState {}

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
