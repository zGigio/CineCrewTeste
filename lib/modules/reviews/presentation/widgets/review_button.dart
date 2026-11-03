// =============================================================================
// modules/reviews/presentation/widgets/review_button.dart
// -----------------------------------------------------------------------------
// BOTÃO "AVALIAR" de uma contratação.
//
// Ao aparecer, pergunta ao servidor se o usuário já avaliou:
//   * ainda não -> botão "Avaliar" (abre a janela de estrelas);
//   * já avaliou -> etiqueta "Avaliado ✓".
// Se ainda não puder avaliar (ex.: pagamento não liberado), o servidor
// devolve a explicação e ela aparece na tela.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/repositories/review_repository.dart';
import 'review_sheet.dart';

class ReviewButton extends StatefulWidget {
  final String applicationId;

  /// Título da janela (ex.: "Avaliar o profissional").
  final String title;

  const ReviewButton({super.key, required this.applicationId, required this.title});

  @override
  State<ReviewButton> createState() => _ReviewButtonState();
}

class _ReviewButtonState extends State<ReviewButton> {
  /// null = ainda verificando.
  bool? _alreadyReviewed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final userId = context.read<SessionCubit>().state.profile!.id;
    final result = await getIt<ReviewRepository>().hasReviewed(
      applicationId: widget.applicationId,
      reviewerId: userId,
    );
    if (!mounted) return;
    // Em caso de erro de rede, mostra o botão (o servidor confere de novo).
    setState(() => _alreadyReviewed = result.getOrElse((_) => false));
  }

  Future<void> _open() async {
    final sent = await showReviewSheet(
      context,
      applicationId: widget.applicationId,
      title: widget.title,
    );
    if (sent && mounted) {
      setState(() => _alreadyReviewed = true);
      showAppMessage(context, 'Obrigado pela avaliação! ⭐');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewed = _alreadyReviewed;
    if (reviewed == null) return const SizedBox.shrink();
    if (reviewed) {
      return const Chip(
        avatar: Icon(Icons.star, size: 18),
        label: Text('Avaliado'),
      );
    }
    return OutlinedButton.icon(
      onPressed: _open,
      icon: const Icon(Icons.star_outline),
      label: const Text('Avaliar'),
    );
  }
}
