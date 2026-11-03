// =============================================================================
// modules/chat/domain/repositories/chat_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do repositório de CHAT (camada de DOMÍNIO).
// =============================================================================

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  /// Conversas do usuário logado, da mais recente para a mais antiga.
  Future<Either<Failure, List<Conversation>>> getConversations();

  /// Procura a conversa sobre uma vaga com outra pessoa (usado pelo botão
  /// "Abrir chat" das candidaturas). `null` se ainda não existir.
  Future<Either<Failure, Conversation?>> findConversation({
    required String jobId,
    required String otherUserId,
  });

  /// "Fluxo" em TEMPO REAL das mensagens de uma conversa (mais antigas
  /// primeiro). Emite a lista atualizada a cada mensagem nova.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Envia uma mensagem.
  Future<Either<Failure, Unit>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  });

  /// Marca como lidas as mensagens RECEBIDAS na conversa.
  Future<Either<Failure, Unit>> markAsRead({
    required String conversationId,
    required String userId,
  });
}
