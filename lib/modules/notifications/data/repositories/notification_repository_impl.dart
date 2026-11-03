// =============================================================================
// modules/notifications/data/repositories/notification_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO das notificações usando o SUPABASE REALTIME.
//
// `.stream(...)` abre uma conexão permanente (WebSocket) com o servidor:
// sempre que a tabela `notifications` muda, o app recebe a lista
// atualizada AUTOMATICAMENTE, sem precisar perguntar de novo.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  static const String _table = 'notifications';

  /// Quantidade máxima de notificações carregadas.
  static const int _limit = 50;

  final SupabaseClient _client;

  NotificationRepositoryImpl(this._client);

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from(_table)
        // primaryKey: coluna que identifica cada linha (para atualizar a lista).
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false) // mais recentes primeiro
        .limit(_limit)
        .map((rows) => rows.map(_fromJson).toList());
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead(String userId) {
    return guardRequest<Unit>(() async {
      // UPDATE notifications SET read_at = agora
      // WHERE user_id = ? AND read_at IS NULL
      await _client
          .from(_table)
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);
      return unit;
    });
  }

  /// Converte uma linha da tabela em [AppNotification].
  static AppNotification _fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'] as String?;
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      applicationId: json['application_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readAt: readAt == null ? null : DateTime.parse(readAt).toLocal(),
    );
  }
}
