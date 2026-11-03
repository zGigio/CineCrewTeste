// =============================================================================
// modules/applications/presentation/pages/my_applications_page.dart
// -----------------------------------------------------------------------------
// TELA "MINHAS CANDIDATURAS" (modo profissional).
//
// Cada cartão mostra a vaga (com MAPA e marcador no local do trabalho), o
// status da candidatura e as ações possíveis:
//   Em análise ......... [Cancelar candidatura]
//   Proposta enviada ... [Aceitar proposta] [Recusar]
//   Contratado ......... [Abrir chat]
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/maps/map_preview.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../chat/presentation/widgets/open_chat_button.dart';
import '../../../jobs/presentation/pages/job_detail_page.dart';
import '../../domain/entities/job_application.dart';
import '../cubit/my_applications_cubit.dart';
import '../widgets/application_status_chip.dart';
import '../../../payments/presentation/widgets/open_payment_button.dart';
import '../../../reviews/presentation/widgets/review_button.dart';

class MyApplicationsPage extends StatelessWidget {
  const MyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;
    return BlocProvider(
      create: (_) => getIt<MyApplicationsCubit>()..load(userId),
      child: const _MyApplicationsView(),
    );
  }
}

class _MyApplicationsView extends StatelessWidget {
  const _MyApplicationsView();

  Future<void> _cancel(BuildContext context, JobApplication application) async {
    final cubit = context.read<MyApplicationsCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Cancelar candidatura',
      message: 'Deseja retirar sua candidatura desta vaga?',
      confirmLabel: 'Cancelar candidatura',
    );
    if (!confirmed) return;
    final error = await cubit.cancel(application);
    if (!context.mounted) return;
    showAppMessage(context, error ?? 'Candidatura cancelada.', isError: error != null);
  }

  Future<void> _respond(
    BuildContext context,
    JobApplication application, {
    required bool accept,
  }) async {
    final cubit = context.read<MyApplicationsCubit>();
    final confirmed = await confirmAction(
      context,
      title: accept ? 'Aceitar proposta' : 'Recusar proposta',
      message: accept
          ? 'Ao aceitar, você será contratado e o chat com o contratante será liberado.'
          : 'Ao recusar, o contratante será avisado. Esta ação não pode ser desfeita.',
      confirmLabel: accept ? 'Aceitar' : 'Recusar',
    );
    if (!confirmed) return;

    final error = await cubit.respondToOffer(application, accept: accept);
    if (!context.mounted) return;
    showAppMessage(
      context,
      error ??
          (accept
              ? 'Proposta aceita! Você foi contratado. 🎉'
              : 'Proposta recusada. O contratante foi avisado.'),
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas candidaturas')),
      body: BlocBuilder<MyApplicationsCubit, ListState<JobApplication>>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar suas candidaturas',
              message: state.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: () => context.read<MyApplicationsCubit>().refresh(),
            );
          }
          if (state.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Você ainda não se candidatou',
              message: 'Use a aba "Buscar vagas" para encontrar trabalhos perto de você.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<MyApplicationsCubit>().refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final application = state.items[index];
                return _ApplicationCard(
                  application: application,
                  onCancel: () => _cancel(context, application),
                  onAccept: () => _respond(context, application, accept: true),
                  onDecline: () => _respond(context, application, accept: false),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Cartão de uma candidatura (visão do profissional).
class _ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ApplicationCard({
    required this.application,
    required this.onCancel,
    required this.onAccept,
    required this.onDecline,
  });

  /// Explicação do status em linguagem simples.
  String get _statusMessage => switch (application.status) {
        ApplicationStatus.pending => 'O contratante ainda está analisando os candidatos.',
        ApplicationStatus.interview =>
          'Parabéns! Você foi aprovado para a entrevista. Aguarde o contato.',
        ApplicationStatus.offerSent =>
          'Você recebeu uma proposta! Aceite para ser contratado e liberar o chat.',
        ApplicationStatus.hired => 'Você foi contratado! O chat com o contratante está liberado.',
        ApplicationStatus.rejected =>
          'Infelizmente você não foi selecionado desta vez. Continue se candidatando!',
        ApplicationStatus.offerDeclined => 'Você recusou esta proposta.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = application.job;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // MAPA com o marcador no local do trabalho.
          if (job != null)
            MapPreview(latitude: job.latitude, longitude: job.longitude, height: 130),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da vaga (tocar abre o detalhe completo).
                InkWell(
                  onTap: job == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => JobDetailPage(job: job)),
                          ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          job?.title ?? 'Vaga removida',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (job != null)
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
                if (job != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      job.requiredRole,
                      Formatters.period(job.startsAt, job.endsAt),
                      if (job.locationLabel.isNotEmpty) job.locationLabel,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (job.recruiterName != null)
                    Text(
                      'Contratante: ${job.recruiterName}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
                const SizedBox(height: 8),
                ApplicationStatusChip(status: application.status),
                const SizedBox(height: 6),
                Text(_statusMessage, style: theme.textTheme.bodyMedium),

                // Ações conforme o status.
                if (application.status == ApplicationStatus.pending)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: onCancel, child: const Text('Cancelar candidatura')),
                  ),
                // Contratado: o chat com o contratante está liberado.
                if (application.status.chatUnlocked && job != null) ...[
                  const SizedBox(height: 8),
                  // Chat + pagamento com garantia lado a lado.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OpenChatButton(jobId: job.id, otherUserId: job.recruiterId),
                      OpenPaymentButton(applicationId: application.id, jobTitle: job.title),
                      ReviewButton(
                        applicationId: application.id,
                        title: 'Avaliar o contratante',
                      ),
                    ],
                  ),
                ],
                if (application.status == ApplicationStatus.offerSent) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          child: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          child: const Text('Aceitar proposta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
