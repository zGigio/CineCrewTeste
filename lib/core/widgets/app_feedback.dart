// =============================================================================
// core/widgets/app_feedback.dart
// -----------------------------------------------------------------------------
// MENSAGENS RÁPIDAS para o usuário (SnackBar).
//
// SnackBar é aquela faixa que aparece rapidamente na parte de baixo da tela
// ("Perfil salvo!", "Senha incorreta"...). Esta função padroniza o visual.
// =============================================================================

import 'package:flutter/material.dart';

/// Mostra uma mensagem rápida na parte inferior da tela.
///
/// Se [isError] for verdadeiro, a faixa aparece na cor de erro (vermelha).
void showAppMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colors = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context)
    // Remove a mensagem anterior (se houver) para não empilhar várias.
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colors.error : null,
      ),
    );
}

/// Exibe uma janela de confirmação com "Cancelar" e um botão de ação.
///
/// Devolve `true` se o usuário confirmou e `false` se cancelou ou fechou.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // `?? false`: se a janela for fechada tocando fora, conta como "não".
  return confirmed ?? false;
}
