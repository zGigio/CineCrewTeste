// =============================================================================
// modules/chat/domain/entities/chat_message.dart
// -----------------------------------------------------------------------------
// ENTIDADE MENSAGEM do chat.
// =============================================================================

import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;

  /// Quem enviou a mensagem.
  final String senderId;

  final String content;
  final DateTime createdAt;

  /// Quando o destinatário leu (nulo = ainda não lida).
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  /// A mensagem foi enviada pelo usuário [userId]? (decide o lado do balão)
  bool isMine(String userId) => senderId == userId;

  @override
  List<Object?> get props => [id, conversationId, senderId, content, createdAt, readAt];
}
