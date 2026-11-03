// =============================================================================
// modules/applications/presentation/pages/job_applications_page.dart
// -----------------------------------------------------------------------------
// TELA "CANDIDATOS DA VAGA" (modo contratante) — o processo seletivo.
//
// Para cada candidato mostra foto, nome, função, status e a mensagem de
// apresentação, com os botões das ações permitidas naquele momento:
//   Em análise ............ [Aprovar p/ entrevista] [Reprovar]
//   Aprovado p/ entrevista  [Contratar (enviar proposta)] [Reprovar]
//   Proposta enviada ...... (aguardando o profissional aceitar)
//   Contratado ............ [Abrir chat]
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../chat/presentation/widgets/open_chat_button.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/pages/job_detail_page.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../../domain/entities/job_application.dart';
import '../cubit/job_applications_cubit.dart';
import '../widgets/application_status_chip.dart';
import '../../../payments/presentation/widgets/open_payment_button.dart';
import '../../../reviews/presentation/widgets/review_button.dart';

class JobApplicationsPage extends StatelessWidget {
  final Job job;

  const JobApplicationsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JobApplicationsCubit>()..load(job.id),
      child: _JobApplicationsView(job: job),
    );
  }
}

class _JobApplicationsView extends StatelessWidget {
  final Job job;

  const _JobApplicationsView({required this.job});

  /// Texto do botão de cada ação do contratante.
  static String _actionLabel(ApplicationStatus status) => switch (status) {
        ApplicationStatus.interview => 'Aprovar p/ entrevista',
        ApplicationStatus.offerSent => 'Contratar',
        ApplicationStatus.rejected => 'Reprovar',
        _ => status.label,
      };

  /// Confirma e executa a mudança de status.
  Future<void> _changeStatus(
    BuildContext context,
    JobApplication application,
    ApplicationStatus newStatus,
  ) async {
    final cubit = context.read<JobApplicationsCubit>();
    final name = application.professional?.firstName ?? 'o candidato';

    // Mensagem de confirmação específica para cada ação.
    final message = switch (newStatus) {
      ApplicationStatus.interview =>
        '$name será avisado de que foi aprovado para a entrevista.',
      ApplicationStatus.offerSent =>
        'Será enviada uma proposta de contratação para $name. '
            'O chat é liberado quando ele(a) aceitar.',
      ApplicationStatus.rejected =>
        '$name será avisado de que não foi selecionado. Esta ação não pode ser desfeita.',
      _ => 'Confirmar alteração?',
    };

    final confirmed = await confirmAction(
      context,
      title: _actionLabel(newStatus),
      message: message,
      confirmLabel: 'Confirmar',
    );
    if (!confirmed) return;

    final error = await cubit.changeStatus(application, newStatus);
    if (!context.mounted) return;
    showAppMessage(
      context,
      error ?? 'Status atualizado: ${newStatus.label}.',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título em duas linhas: "Candidatos" + nome da vaga.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Candidatos'),
            Text(
              job.title,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver vaga',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => JobDetailPage(job: job)),
            ),
          ),
        ],
      ),
      body: BlocBuilder<JobApplicationsCubit, ListState<JobApplication>>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar os candidatos',
              message: state.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: () => context.read<JobApplicationsCubit>().refresh(),
            );
          }
          if (state.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'Nenhum candidato ainda',
              message: 'Você será avisado quando alguém se candidatar.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<JobApplicationsCubit>().refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final application = state.items[index];
                return _CandidateCard(
                  application: application,
                  jobTitle: job.title,
                  actionLabel: _actionLabel,
                  onAction: (newStatus) => _changeStatus(context, application, newStatus),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Cartão de um candidato com as ações disponíveis.
class _CandidateCard extends StatelessWidget {
  final JobApplication application;

  /// Título da vaga (mostrado na tela de pagamento).
  final String jobTitle;
  final String Function(ApplicationStatus) actionLabel;
  final ValueChanged<ApplicationStatus> onAction;

  const _CandidateCard({
    required this.application,
    required this.jobTitle,
    required this.actionLabel,
    required this.onAction,
  });

  /// Texto informativo para status que não têm ação do contratante.
  String? get _waitingText => switch (application.status) {
        ApplicationStatus.offerSent => 'Aguardando o profissional aceitar a proposta.',
        ApplicationStatus.hired => 'Contratado! O chat e o pagamento com garantia foram liberados.',
        ApplicationStatus.offerDeclined => 'O profissional recusou a proposta.',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final professional = application.professional;
    final name = professional?.fullName ?? 'Profissional';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: foto, nome, função e data da candidatura.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(imageUrl: professional?.avatarUrl, name: name),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                [
                  if (professional?.primaryRole != null) professional!.primaryRole!,
                  'Candidatou-se em ${Formatters.date(application.createdAt)}',
                ].join('\n'),
              ),
              isThreeLine: true,
            ),
            ApplicationStatusChip(status: application.status),

            // Mensagem de apresentação.
            if (application.coverMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('"${application.coverMessage!}"'),
              ),
            ],

            if (_waitingText != null) ...[
              const SizedBox(height: 8),
              Text(_waitingText!, style: theme.textTheme.bodySmall),
            ],

            const SizedBox(height: 8),
            // Botões: ver perfil + ações permitidas no status atual.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PublicProfilePage(userId: application.professionalId),
                    ),
                  ),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Ver perfil e currículo'),
                ),
                // Contratado: abre o chat com o profissional.
                if (application.status.chatUnlocked) ...[
                  OpenChatButton(
                    jobId: application.jobId,
                    otherUserId: application.professionalId,
                  ),
                  // Pagamento com garantia da contratação.
                  OpenPaymentButton(applicationId: application.id, jobTitle: jobTitle),
                  ReviewButton(
                    applicationId: application.id,
                    title: 'Avaliar o profissional',
                  ),
                ],
                for (final next in application.status.recruiterActions)
                  next == ApplicationStatus.rejected
                      ? TextButton(
                          onPressed: () => onAction(next),
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: Text(actionLabel(next)),
                        )
                      : FilledButton(
                          onPressed: () => onAction(next),
                          child: Text(actionLabel(next)),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
