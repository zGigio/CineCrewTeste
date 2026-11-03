// =============================================================================
// modules/notifications/domain/entities/app_notification.dart
// -----------------------------------------------------------------------------
// ENTIDADE NOTIFICAÇÃO: aviso exibido no sino 🔔 do app.
//
// As notificações são criadas AUTOMATICAMENTE pelo banco de dados (gatilho
// on_application_event no schema.sql) quando algo acontece no processo
// seletivo: nova candidatura, aprovação para entrevista, reprovação,
// proposta enviada, aceita ou recusada.
// =============================================================================

import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;

  /// Candidatura relacionada (para abrir a tela certa no futuro).
  final String? applicationId;

  final DateTime createdAt;

  /// Quando foi lida (nulo = ainda não lida).
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.applicationId,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, title, body, applicationId, createdAt, readAt];
}
