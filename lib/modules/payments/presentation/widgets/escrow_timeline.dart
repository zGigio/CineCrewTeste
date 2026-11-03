// =============================================================================
// modules/payments/presentation/widgets/escrow_timeline.dart
// -----------------------------------------------------------------------------
// LINHA DO TEMPO DA GARANTIA (3 etapas):
//
//   (1)───────(2)───────(3)
//   Pagamento  Em        Liberado
//              garantia
//
// Etapas concluídas ficam em âmbar com ✓; a atual fica destacada.
// =============================================================================

import 'package:flutter/material.dart';

class EscrowTimeline extends StatelessWidget {
  /// Etapa atual: 0, 1 ou 2.
  final int currentStep;

  /// Etapa 2 em disputa: mostra o ícone de alerta.
  final bool isDisputed;

  const EscrowTimeline({super.key, required this.currentStep, this.isDisputed = false});

  static const _labels = ['Pagamento', 'Em garantia', 'Liberado'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          // Linha de ligação entre as bolinhas.
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 22),
                color: i <= currentStep ? colors.primary : colors.outlineVariant,
              ),
            ),
          _StepDot(
            index: i,
            label: _labels[i],
            done: i < currentStep || (i == 2 && currentStep == 2),
            active: i == currentStep,
            warning: isDisputed && i == currentStep,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final bool active;
  final bool warning;

  const _StepDot({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlighted = done || active;

    final Widget content = warning
        ? Icon(Icons.priority_high, size: 18, color: colors.onError)
        : done
            ? Icon(Icons.check, size: 18, color: colors.onPrimary)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: highlighted ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: warning
              ? colors.error
              : highlighted
                  ? colors.primary
                  : colors.surfaceContainerHighest,
          child: content,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
