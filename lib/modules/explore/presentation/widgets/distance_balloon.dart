// =============================================================================
// modules/explore/presentation/widgets/distance_balloon.dart
// -----------------------------------------------------------------------------
// BALÃO DE DISTÂNCIA no mapa de resultados (TEL13): "≈ 9 km".
// Branco com borda; o selecionado fica azul-marinho com texto branco.
// O balão fica na POSIÇÃO APROXIMADA (pode ficar perto da borda do círculo,
// pois a decisão "está no raio?" usa a coordenada exata — pendência P16).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DistanceBalloon extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DistanceBalloon({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Profissional a $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
