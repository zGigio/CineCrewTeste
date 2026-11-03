// =============================================================================
// core/widgets/labeled_field.dart
// -----------------------------------------------------------------------------
// CAMPO COM RÓTULO EM CIMA (padrão das pranchas da documentação):
//
//   E-mail                 <- rótulo 13, negrito, cor secundária
//   [✉ nome@exemplo.com ]  <- o campo em si (qualquer widget)
//
// O rótulo fica fora da caixa para continuar visível enquanto a pessoa
// digita (o "label" flutuante do Material some/encolhe).
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
