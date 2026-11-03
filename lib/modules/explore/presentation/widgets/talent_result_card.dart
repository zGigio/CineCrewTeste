// =============================================================================
// modules/explore/presentation/widgets/talent_result_card.dart
// -----------------------------------------------------------------------------
// CARTÃO DE RESULTADO (TEL12), como no design system:
//
//   ┌───────────────────────────────┐
//   │  ilustração do set            │
//   │ (RA)                          │
//   ├───────────────────────────────┤
//   │ Rafael Antunes                │
//   │ Eletricista                   │
//   │ ≈ 3 km do set  posição aprox. │
//   └───────────────────────────────┘
//
// A ilustração é decorativa (sugestão S01): a paleta é escolhida pelo id
// da pessoa, então cada profissional tem sempre a mesma.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/set_illustration.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/talent_result.dart';

class TalentResultCard extends StatelessWidget {
  final TalentResult talent;
  final VoidCallback onTap;

  const TalentResultCard({super.key, required this.talent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${talent.name}, ${talent.specialties.join(', ')}, '
          '${talent.distanceLabel}, posição aproximada',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SetIllustration(palette: SetPalette.fromSeed(talent.id)),
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.surface,
                        child: UserAvatar(
                          imageUrl: talent.avatarUrl,
                          name: talent.name,
                          radius: 27,
                        ),
                      ),
                    ),
                    if (!talent.isAvailable)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warningBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Indisponível',
                            style: TextStyle(color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(talent.name, style: theme.textTheme.titleMedium),
                    if (talent.specialties.isNotEmpty)
                      Text(
                        talent.specialties.take(2).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          talent.distanceLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('posição aproximada', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TEL12-E1: "esqueleto" no formato do cartão enquanto carrega.
class TalentResultSkeleton extends StatelessWidget {
  const TalentResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => Container(
          width: width,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.supportBackground,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return ExcludeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 112, color: AppColors.supportBackground),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [bar(150), const SizedBox(height: 8), bar(100)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
