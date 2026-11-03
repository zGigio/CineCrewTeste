// =============================================================================
// modules/home/presentation/widgets/recruiter_quick_actions.dart
// -----------------------------------------------------------------------------
// ATALHO EXTRA DO CONTRATANTE (fora da documentação): publicar uma vaga.
//   [ ➕ Publicar uma vaga ]
// =============================================================================

import 'package:flutter/material.dart';

import '../../../jobs/presentation/pages/create_job_page.dart';

class RecruiterQuickActions extends StatelessWidget {
  /// Chamado depois que uma vaga é publicada (para ir até "Minhas vagas").
  final VoidCallback onJobCreated;

  const RecruiterQuickActions({super.key, required this.onJobCreated});

  @override
  Widget build(BuildContext context) {
    // A busca de talentos agora é o próprio Explorar (TEL10 a TEL13);
    // aqui fica só o atalho extra para publicar uma vaga.
    return _ActionCard(
      icon: Icons.add_circle_outline,
      title: 'Publicar uma vaga',
      subtitle: 'Marque o local do set no mapa e receba candidaturas',
      onTap: () async {
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const CreateJobPage()),
        );
        if (created == true) onJobCreated();
      },
    );
  }
}

/// Cartão de atalho: ícone grande + título + subtítulo.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
