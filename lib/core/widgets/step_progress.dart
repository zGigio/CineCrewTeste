// =============================================================================
// core/widgets/step_progress.dart
// -----------------------------------------------------------------------------
// INDICADOR DE PASSOS (formulários em etapas, ex.: perfil profissional):
//
//   ▬▬▬▬ ▬▬▬▬ ──── ────     Passo 2 de 4
//
// Etapas feitas e a atual em âmbar; as próximas em cinza.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StepProgress extends StatelessWidget {
  /// Passo atual, começando em 1.
  final int current;
  final int total;

  const StepProgress({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Passo $current de $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var step = 1; step <= total; step++) ...[
                if (step > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: step <= current ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text('Passo $current de $total', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
