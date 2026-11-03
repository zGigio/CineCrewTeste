// =============================================================================
// modules/jobs/presentation/pages/job_detail_page.dart
// -----------------------------------------------------------------------------
// DETALHE DA VAGA: mapa do local (com marcador), período, cachê, descrição
// e contratante. No rodapé, a barra "Candidatar-se" (ApplyBar), que só
// aparece para profissionais que não sejam o dono da vaga.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/maps/map_preview.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../applications/presentation/widgets/apply_bar.dart';
import '../../domain/entities/job.dart';

class JobDetailPage extends StatelessWidget {
  final Job job;

  const JobDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da vaga')),
      // Rodapé fixo com o botão de candidatura (ou o status, se já enviou).
      bottomNavigationBar: ApplyBar(job: job),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ONDE: mapa com o local da gravação.
          MapPreview(latitude: job.latitude, longitude: job.longitude),
          const SizedBox(height: 16),

          Text(
            job.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(job.requiredRole, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          // Quadro com as informações principais.
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Cachê'),
                  trailing: Text(
                    Formatters.currency(job.fee),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Quando'),
                  subtitle: Text(Formatters.period(job.startsAt, job.endsAt)),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('Onde'),
                  subtitle: Text(
                    [
                      if (job.address != null && job.address!.isNotEmpty) job.address!,
                      if (job.locationLabel.isNotEmpty) job.locationLabel,
                      if (job.distanceInKm != null)
                        'a ${Formatters.distance(job.distanceInKm!)} de você',
                    ].join('\n'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Situação'),
                  trailing: Text(job.status.label),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (job.description.isNotEmpty) ...[
            Text('Descrição', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(job.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],

          // Quem publicou a vaga.
          Text('Publicada por', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(
              imageUrl: job.recruiterAvatarUrl,
              name: job.recruiterName ?? '?',
            ),
            title: Text(job.recruiterName ?? 'Contratante'),
          ),
        ],
      ),
    );
  }
}
