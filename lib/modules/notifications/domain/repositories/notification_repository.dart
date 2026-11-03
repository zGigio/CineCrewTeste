// =============================================================================
// modules/notifications/domain/repositories/notification_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do repositório de NOTIFICAÇÕES (camada de DOMÍNIO).
// =============================================================================

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  /// "Fluxo" em TEMPO REAL das notificações do usuário: emite uma lista
  /// nova sempre que uma notificação é criada ou alterada no banco.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Marca todas as notificações do usuário como lidas.
  Future<Either<Failure, Unit>> markAllAsRead(String userId);
}
