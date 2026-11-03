// =============================================================================
// modules/chat/data/repositories/chat_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do chat usando o SUPABASE.
//
//   * Lista de conversas -> função SQL `get_my_conversations` (RPC);
//   * Mensagens          -> tabela `messages` + SUPABASE REALTIME:
//     `.stream(...)` mantém uma conexão aberta (WebSocket) e o app recebe
//     cada mensagem nova na hora, sem precisar atualizar a tela.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _client;

  ChatRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() {
    return guardRequest<List<Conversation>>(() async {
      final response = await _client.rpc('get_my_conversations');
      final rows = response as List<dynamic>;
      return rows
          .map((row) => _conversationFromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Either<Failure, Conversation?>> findConversation({
    required String jobId,
    required String otherUserId,
  }) async {
    // Reaproveita a lista completa (já tem nome, foto e não lidas) e
    // procura a conversa daquela vaga com aquela pessoa.
    final result = await getConversations();
    return result.map(
      (conversations) => conversations
          .where((c) => c.jobId == jobId && c.otherUserId == otherUserId)
          .firstOrNull,
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true) // mais antigas primeiro
        .map((rows) => rows.map(_messageFromJson).toList());
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    return guardRequest<Unit>(() async {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      });
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> markAsRead({
    required String conversationId,
    required String userId,
  }) {
    return guardRequest<Unit>(() async {
      // UPDATE messages SET read_at = agora
      // WHERE conversation_id = ? AND sender_id <> eu AND read_at IS NULL
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);
      return unit;
    });
  }

  // ---------------------------------------------------------------------------
  // Conversão JSON -> entidades
  // ---------------------------------------------------------------------------

  static Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      jobId: json['job_id'] as String?,
      jobTitle: json['job_title'] as String?,
      otherUserId: json['other_user_id'] as String,
      otherUserName: (json['other_user_name'] as String?) ?? 'Usuário',
      otherUserAvatarUrl: json['other_user_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String).toLocal(),
      // count(*) do PostgreSQL chega como número inteiro.
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readAt: readAt == null ? null : DateTime.parse(readAt).toLocal(),
    );
  }
}
