// =============================================================================
// modules/chat/presentation/widgets/message_bubble.dart
// -----------------------------------------------------------------------------
// BALÃO DE MENSAGEM do chat.
//   - Minhas mensagens: à direita, na cor de destaque (âmbar).
//   - Mensagens do outro: à esquerda, em cinza.
// Mostra o horário e, nas minhas, o "visto" (✓ enviada / ✓✓ lida).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  /// A mensagem é do usuário logado?
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isMine ? colors.primary : colors.surfaceContainerHighest;
    final foreground = isMine ? colors.onPrimary : colors.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // O balão ocupa no máximo 78% da largura da tela.
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          decoration: BoxDecoration(
            color: background,
            // Cantos arredondados, com a "pontinha" do lado de quem enviou.
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.content, style: TextStyle(color: foreground, fontSize: 15)),
              const SizedBox(height: 2),
              // Horário + visto.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.time(message.createdAt),
                    style: TextStyle(color: foreground.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
