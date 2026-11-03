// =============================================================================
// modules/chat/presentation/pages/conversations_page.dart
// -----------------------------------------------------------------------------
// TELA "MENSAGENS": lista de conversas, no estilo do LinkedIn.
//
//   [foto] Ana Souza                    14:32
//          Vaga: Videomaker casamento
//          Chegada às 7h. Até lá!         (2)
//
// As conversas só existem depois que um profissional ACEITA a proposta.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/conversation.dart';
import '../cubit/conversations_cubit.dart';
import 'chat_page.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConversationsCubit>()..load(),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  /// Abre a conversa e, ao voltar, recarrega a lista (zera as não lidas).
  Future<void> _open(BuildContext context, Conversation conversation) async {
    final cubit = context.read<ConversationsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatPage(conversation: conversation)),
    );
    await cubit.load();
  }

  /// Hoje mostra a hora; em outros dias, a data.
  String _timeLabel(DateTime value) {
    final now = DateTime.now();
    final isToday =
        value.year == now.year && value.month == now.month && value.day == now.day;
    return isToday ? Formatters.time(value) : Formatters.date(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens'), actions: const [ModeIndicatorChip()]),
      body: BlocBuilder<ConversationsCubit, ListState<Conversation>>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar as conversas',
              message: state.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: () => context.read<ConversationsCubit>().load(),
            );
          }
          if (state.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'Nenhuma conversa ainda',
              message: 'O chat é liberado quando o profissional aceita uma '
                  'proposta de contratação.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ConversationsCubit>().load(),
            child: ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final conversation = state.items[index];
                final unread = conversation.hasUnread;

                return ListTile(
                  onTap: () => _open(context, conversation),
                  leading: UserAvatar(
                    imageUrl: conversation.otherUserAvatarUrl,
                    name: conversation.otherUserName,
                  ),
                  title: Text(
                    conversation.otherUserName,
                    style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.w500),
                  ),
                  subtitle: Text(
                    [
                      if (conversation.jobTitle != null) 'Vaga: ${conversation.jobTitle}',
                      conversation.lastMessage ?? 'Diga olá! 👋',
                    ].join('\n'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                      color: unread ? theme.colorScheme.onSurface : null,
                    ),
                  ),
                  isThreeLine: true,
                  // Horário + bolinha com a quantidade de não lidas.
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_timeLabel(conversation.lastMessageAt), style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      if (unread)
                        Badge(label: Text('${conversation.unreadCount}')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
