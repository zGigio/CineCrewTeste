// =============================================================================
// modules/chat/presentation/pages/chat_page.dart
// -----------------------------------------------------------------------------
// TELA DE CONVERSA (chat em tempo real).
//
//   [foto] Nome da pessoa
//          Vaga: Videomaker para casamento
//   ---------------------------------------
//                    [Oi! Tudo certo?] ✓✓
//   [Tudo! Chego às 7h.]
//   ---------------------------------------
//   [ Escreva uma mensagem...        ] (➤)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatelessWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;
    return BlocProvider(
      create: (_) => getIt<ChatCubit>()
        ..open(conversationId: conversation.id, userId: userId),
      child: _ChatView(conversation: conversation, userId: userId),
    );
  }
}

class _ChatView extends StatefulWidget {
  final Conversation conversation;
  final String userId;

  const _ChatView({required this.conversation, required this.userId});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    // Limpa o campo na hora (sensação de rapidez); se der erro, devolve o texto.
    _textController.clear();
    final error = await context.read<ChatCubit>().send(text);
    if (!mounted || error == null) return;
    _textController.text = text;
    showAppMessage(context, error, isError: true);
  }

  /// Mostra a data ("12/03/2026") quando o dia muda entre duas mensagens.
  bool _isNewDay(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // Tocar no cabeçalho abre o perfil da outra pessoa.
        title: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PublicProfilePage(userId: conversation.otherUserId),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: conversation.otherUserAvatarUrl,
                name: conversation.otherUserName,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation.otherUserName, overflow: TextOverflow.ellipsis),
                    if (conversation.jobTitle != null)
                      Text(
                        'Vaga: ${conversation.jobTitle}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Lista de mensagens.
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Vocês foram conectados! 🎬\n'
                        'Combine os detalhes do trabalho por aqui.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final messages = state.messages;
                // `reverse: true`: a lista começa de BAIXO (mensagem mais
                // nova sempre visível, como em qualquer app de mensagens).
                // Por isso percorremos as mensagens de trás para frente.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, reversedIndex) {
                    final index = messages.length - 1 - reversedIndex;
                    final message = messages[index];
                    return Column(
                      children: [
                        if (_isNewDay(messages, index))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Chip(
                              label: Text(Formatters.date(message.createdAt)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        MessageBubble(
                          message: message,
                          isMine: message.isMine(widget.userId),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Campo de digitação + botão de enviar.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 5, // cresce até 5 linhas
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escreva uma mensagem...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  BlocBuilder<ChatCubit, ChatState>(
                    buildWhen: (previous, current) => previous.isSending != current.isSending,
                    builder: (context, state) => IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: state.isSending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
