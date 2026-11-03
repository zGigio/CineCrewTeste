// =============================================================================
// modules/professional/presentation/widgets/visibility_status_card.dart
// -----------------------------------------------------------------------------
// CARTÃO DE VISIBILIDADE do Painel (TEL16):
//
//   ✓ Seu perfil aparece nas buscas          (verde)
//   ✓ Especialidades definidas
//   ✓ Localização-base confirmada
//   ✓ Aceite de uso da localização registrado
//   ✗ Portfólio (opcional)
//
// A etiqueta "aparece nas buscas" só é mostrada com perfil ativo, completo
// e localização válida (RN13). Sem isso, o cartão fica em ALERTA.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/entities/user_profile.dart';

class VisibilityStatusCard extends StatelessWidget {
  final UserProfile profile;

  /// Quantidade de itens no portfólio (`null` = ainda carregando).
  final int? portfolioCount;

  const VisibilityStatusCard({super.key, required this.profile, this.portfolioCount});

  @override
  Widget build(BuildContext context) {
    final visible = profile.isVisibleInSearch;
    final background = visible ? AppColors.successBackground : AppColors.warningBackground;
    final foreground = visible ? AppColors.success : AppColors.warning;

    final items = <(String, bool)>[
      ('Especialidades definidas', profile.primaryRole?.isNotEmpty ?? false),
      ('Localização-base confirmada', profile.hasLocation),
      ('Aceite de uso da localização registrado', profile.hasLocationConsent),
      ('Portfólio (opcional)', (portfolioCount ?? 0) > 0),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visible ? Icons.check : Icons.warning_rounded, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visible
                      ? 'Seu perfil aparece nas buscas'
                      : 'Seu perfil ainda não aparece nas buscas',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (label, done) in items)
            Semantics(
              label: '$label: ${done ? 'feito' : 'pendente'}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check : Icons.close,
                      size: 18,
                      color: done ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
