// =============================================================================
// modules/notifications/presentation/pages/notifications_page.dart
// -----------------------------------------------------------------------------
// TELA DE NOTIFICAÇÕES: lista os avisos do processo seletivo
// (aprovado, reprovado, proposta recebida/aceita/recusada...).
// Ao abrir, todas são marcadas como lidas (o número do sino zera).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Marca como lidas ao abrir. As NÃO lidas continuam destacadas
    // nesta visita, porque a lista exibida ainda é a de antes.
    context.read<NotificationsCubit>().markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: BlocBuilder<NotificationsCubit, List<AppNotification>>(
        builder: (context, notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'Nenhuma notificação',
              message: 'Os avisos das suas candidaturas e vagas aparecem aqui.',
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                // Fundo levemente colorido para as não lidas.
                tileColor: notification.isRead
                    ? null
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                leading: Icon(
                  notification.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${notification.body}\n${Formatters.dateTime(notification.createdAt)}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
