// =============================================================================
// modules/jobs/presentation/widgets/job_card.dart
// -----------------------------------------------------------------------------
// CARTÃO DE VAGA usado nas listas (busca e "Minhas vagas").
//
//   [ícone]  Título da vaga                         R$ 1.500,00
//            Videomaker
//            📅 07/03/2026, 08:00 às 18:00
//            📍 Rio de Janeiro - RJ · 7,2 km
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Monta "Cidade - UF · 7,2 km" só com as partes que existirem.
    final placeParts = [
      if (job.locationLabel.isNotEmpty) job.locationLabel,
      if (job.distanceInKm != null) Formatters.distance(job.distanceInKm!),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone de câmera em um quadrado colorido.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.videocam_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              // Informações principais (ocupam o espaço que sobrar).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(job.requiredRole, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      text: Formatters.period(job.startsAt, job.endsAt),
                    ),
                    if (placeParts.isNotEmpty)
                      _InfoLine(
                        icon: Icons.place_outlined,
                        text: placeParts.join(' · '),
                      ),
                    // Etiqueta "Encerrada" quando a vaga não aceita mais candidatos.
                    if (!job.isOpen)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Chip(
                          label: Text(job.status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cachê em destaque.
              Text(
                Formatters.currency(job.fee),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha pequena com ícone + texto (data, local...).
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
