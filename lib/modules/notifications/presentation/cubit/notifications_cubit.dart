// =============================================================================
// modules/notifications/presentation/cubit/notifications_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DAS NOTIFICAÇÕES: escuta o fluxo em tempo real e guarda a lista
// atual. A quantidade de NÃO LIDAS aparece no sino 🔔 da tela inicial.
// =============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

@injectable
class NotificationsCubit extends Cubit<List<AppNotification>> {
  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _subscription;
  String? _userId;

  NotificationsCubit(this._repository) : super(const []);

  /// Quantidade de notificações ainda não lidas.
  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Começa a escutar as notificações do usuário.
  void watch(String userId) {
    _userId = userId;
    _subscription?.cancel();
    _subscription = _repository.watchNotifications(userId).listen(
          emit,
          // Se a conexão de tempo real falhar, mantém a lista atual.
          onError: (_) {},
        );
  }

  /// Marca tudo como lido (ao abrir a tela de notificações).
  Future<void> markAllAsRead() async {
    final id = _userId;
    if (id == null || unreadCount == 0) return;
    await _repository.markAllAsRead(id);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
