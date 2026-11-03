// =============================================================================
// modules/chat/presentation/widgets/open_chat_button.dart
// -----------------------------------------------------------------------------
// BOTÃO "ABRIR CHAT" usado nas candidaturas com status CONTRATADO.
//
// Procura a conversa (criada pelo banco quando a proposta foi aceita) entre
// o usuário logado e a outra pessoa, sobre aquela vaga, e abre a tela do chat.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/repositories/chat_repository.dart';
import '../pages/chat_page.dart';

class OpenChatButton extends StatefulWidget {
  final String jobId;

  /// A outra pessoa da conversa (contratante ou profissional).
  final String otherUserId;

  const OpenChatButton({super.key, required this.jobId, required this.otherUserId});

  @override
  State<OpenChatButton> createState() => _OpenChatButtonState();
}

class _OpenChatButtonState extends State<OpenChatButton> {
  bool _isOpening = false;

  Future<void> _open() async {
    setState(() => _isOpening = true);
    final result = await getIt<ChatRepository>().findConversation(
      jobId: widget.jobId,
      otherUserId: widget.otherUserId,
    );
    if (!mounted) return;
    setState(() => _isOpening = false);

    final conversation = result.fold(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return null;
      },
      (found) => found,
    );
    if (conversation == null) {
      if (result.isRight()) {
        showAppMessage(context, 'A conversa ainda não foi liberada.', isError: true);
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatPage(conversation: conversation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isOpening ? null : _open,
      icon: _isOpening
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline),
      label: const Text('Abrir chat'),
    );
  }
}
