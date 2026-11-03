// =============================================================================
// modules/jobs/presentation/pages/recruiter_jobs_page.dart
// -----------------------------------------------------------------------------
// TELA "MINHAS VAGAS" (modo contratante).
//
// Lista as vagas publicadas pelo usuário, com:
//   - botão "Nova vaga" (abre a tela de publicação);
//   - "puxar para atualizar" (RefreshIndicator);
//   - menu de cada vaga com a opção "Encerrar vaga";
//   - tocar na vaga abre a lista de CANDIDATOS (processo seletivo).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/pages/job_applications_page.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/job.dart';
import '../cubit/recruiter_jobs_cubit.dart';
import '../widgets/job_card.dart';
import 'create_job_page.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';

class RecruiterJobsPage extends StatelessWidget {
  const RecruiterJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;

    // Cria o cubit e já manda carregar as vagas do usuário logado.
    // O operador ".." (cascata) chama `load` e devolve o próprio cubit.
    return BlocProvider(
      create: (_) => getIt<RecruiterJobsCubit>()..load(userId),
      child: const _RecruiterJobsView(),
    );
  }
}

class _RecruiterJobsView extends StatelessWidget {
  const _RecruiterJobsView();

  /// Abre a tela de publicação; se publicou, recarrega a lista.
  Future<void> _openCreate(BuildContext context) async {
    final cubit = context.read<RecruiterJobsCubit>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobPage()),
    );
    if (created == true) await cubit.refresh();
  }

  /// Pergunta e encerra a vaga.
  Future<void> _closeJob(BuildContext context, Job job) async {
    final cubit = context.read<RecruiterJobsCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Encerrar vaga',
      message: 'A vaga "${job.title}" deixará de aparecer nas buscas. Continuar?',
      confirmLabel: 'Encerrar',
    );
    if (!confirmed) return;

    final error = await cubit.closeJob(job);
    if (!context.mounted) return;
    showAppMessage(
      context,
      error ?? 'Vaga encerrada.',
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas vagas'), actions: const [ModeIndicatorChip()]),
      // Botão flutuante estendido (com ícone e texto).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova vaga'),
      ),
      body: BlocBuilder<RecruiterJobsCubit, ListState<Job>>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar suas vagas',
              message: state.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: () => context.read<RecruiterJobsCubit>().refresh(),
            );
          }
          if (state.isEmpty) {
            return EmptyState(
              icon: Icons.work_outline,
              title: 'Você ainda não publicou vagas',
              message: 'Publique uma vaga e encontre profissionais perto do set.',
              actionLabel: 'Publicar vaga',
              onAction: () => _openCreate(context),
            );
          }
          // RefreshIndicator: arrastar a lista para baixo recarrega.
          return RefreshIndicator(
            onRefresh: () => context.read<RecruiterJobsCubit>().refresh(),
            child: ListView.separated(
              // Espaço extra embaixo para o botão flutuante não cobrir o último cartão.
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final job = state.items[index];
                return Stack(
                  children: [
                    JobCard(
                      job: job,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JobApplicationsPage(job: job),
                        ),
                      ),
                    ),
                    // Menu de opções (⋮) no canto inferior direito do cartão.
                    if (job.isOpen)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: PopupMenuButton<String>(
                          tooltip: 'Opções',
                          onSelected: (_) => _closeJob(context, job),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'close', child: Text('Encerrar vaga')),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
