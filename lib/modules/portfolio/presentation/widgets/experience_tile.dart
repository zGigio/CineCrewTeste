// =============================================================================
// modules/portfolio/presentation/widgets/experience_tile.dart
// -----------------------------------------------------------------------------
// UMA EXPERIÊNCIA na lista (como no LinkedIn):
//   [ícone]  Videomaker
//            Casamento Ana & Leo · Casamento
//            mar. 2024 – atual · 8 meses
//            Descrição...
// =============================================================================

import 'package:flutter/material.dart';

import '../../domain/entities/experience.dart';

class ExperienceTile extends StatelessWidget {
  final Experience experience;

  /// Ações opcionais (só na tela de edição).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExperienceTile({super.key, required this.experience, this.onEdit, this.onDelete});

  /// Ícone conforme o tipo de projeto.
  static IconData iconFor(String? category) => switch (category) {
        'Filme' => Icons.movie_outlined,
        'Série' => Icons.live_tv_outlined,
        'Publicidade' => Icons.campaign_outlined,
        'Videoclipe' => Icons.music_video_outlined,
        'Evento' => Icons.celebration_outlined,
        'Casamento' => Icons.favorite_outline,
        'Institucional' => Icons.business_outlined,
        _ => Icons.work_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconFor(experience.category), color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.role,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    [experience.production, if (experience.category != null) experience.category!]
                        .join(' · '),
                  ),
                  Text('${experience.periodLabel} · ${experience.durationLabel()}', style: muted),
                  if (experience.description != null) ...[
                    const SizedBox(height: 4),
                    Text(experience.description!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Apagar',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}
