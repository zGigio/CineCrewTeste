// =============================================================================
// modules/notifications/presentation/widgets/notification_bell.dart
// -----------------------------------------------------------------------------
// SINO 🔔 com o número de notificações não lidas (Badge).
// Ao tocar, abre a tela de notificações.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../pages/notifications_page.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, List<AppNotification>>(
      builder: (context, notifications) {
        final cubit = context.read<NotificationsCubit>();
        final unread = cubit.unreadCount;

        return IconButton(
          tooltip: 'Notificações',
          // Badge: bolinha com o número sobre o ícone (some quando é zero).
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              // BlocProvider.value: leva o MESMO cubit para a nova tela
              // (rotas novas não enxergam os providers da tela anterior).
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const NotificationsPage(),
              ),
            ),
          ),
        );
      },
    );
  }
}
