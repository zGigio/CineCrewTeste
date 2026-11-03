// =============================================================================
// modules/reviews/presentation/widgets/review_sheet.dart
// -----------------------------------------------------------------------------
// JANELA "AVALIAR" (aberta de baixo para cima): estrelas + comentário.
// Devolve `true` se a avaliação foi enviada com sucesso.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import 'rating_stars.dart';

Future<bool> showReviewSheet(
  BuildContext context, {
  required String applicationId,
  required String title,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // sobe junto com o teclado
    showDragHandle: true,
    builder: (_) => _ReviewSheet(applicationId: applicationId, title: title),
  );
  return sent ?? false;
}

class _ReviewSheet extends StatefulWidget {
  final String applicationId;
  final String title;

  const _ReviewSheet({required this.applicationId, required this.title});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    final result = await getIt<SubmitReviewUseCase>()(
      SubmitReviewParams(
        applicationId: widget.applicationId,
        rating: _rating,
        comment: _commentController.text,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isSending = false;
        _error = failure.message;
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          StarRatingInput(
            value: _rating,
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: SubmitReviewUseCase.maxCommentLength,
            decoration: const InputDecoration(
              labelText: 'Comentário (opcional)',
              hintText: 'Como foi trabalhar junto? Pontualidade, qualidade, comunicação...',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          FilledButton(
            // Só libera o botão depois de escolher as estrelas.
            onPressed: _rating == 0 || _isSending ? null : _send,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar avaliação'),
          ),
          const SizedBox(height: 4),
          Text(
            'A avaliação fica visível no perfil e não pode ser alterada depois.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
