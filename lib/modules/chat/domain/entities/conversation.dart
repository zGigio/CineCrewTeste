// =============================================================================
// modules/chat/domain/entities/conversation.dart
// -----------------------------------------------------------------------------
// ENTIDADE CONVERSA (camada de DOMÍNIO).
//
// Uma conversa entre CONTRATANTE e PROFISSIONAL, criada automaticamente pelo
// banco quando o profissional ACEITA a proposta de contratação.
// Já traz os dados da outra pessoa e a última mensagem, para montar a lista
// no estilo das mensagens do LinkedIn.
// =============================================================================

import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;

  /// Vaga que originou a conversa.
  final String? jobId;
  final String? jobTitle;

  /// A OUTRA pessoa da conversa (quem não é o usuário logado).
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  /// Última mensagem trocada (nula se ainda ninguém escreveu).
  final String? lastMessage;
  final DateTime lastMessageAt;

  /// Mensagens recebidas ainda não lidas.
  final int unreadCount;

  const Conversation({
    required this.id,
    this.jobId,
    this.jobTitle,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        otherUserId,
        otherUserName,
        otherUserAvatarUrl,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
