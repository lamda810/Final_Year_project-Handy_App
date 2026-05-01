import 'package:equatable/equatable.dart';

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class SendChatMessage extends ChatbotEvent {
  final String message;
  final String? city;
  final String? area;

  const SendChatMessage({
    required this.message,
    this.city,
    this.area,
  });

  @override
  List<Object?> get props => [message, city, area];
}

class ResetChatbot extends ChatbotEvent {}
