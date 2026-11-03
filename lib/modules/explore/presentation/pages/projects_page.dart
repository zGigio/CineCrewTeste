// =============================================================================
// modules/explore/presentation/pages/projects_page.dart
// -----------------------------------------------------------------------------
// TEL15 — MEUS PROJETOS (modo Contratar).
//
//   [ilustração] Longa "Horizonte Seco"            >
//                Petrolina · PE · raio 50 km
//                (Direção de fotografia) (Eletricista)
//                                        [+ Novo projeto]
//
// Tocar no projeto repete a busca dele (TEL12). Pelo menu ⋮ dá para editar
// ou apagar. TEL15-E1: nenhum projeto ainda.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/set_illustration.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../domain/entities/project.dart';
import '../cubit/projects_cubit.dart';
import '../explore_navigation.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  Future<void> _delete(BuildContext context, Project project) async {
    final cubit = context.read<ProjectsCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Apagar projeto?',
      message: '"${project.name}" sai da sua lista. Isso não afeta nenhum profissional.',
      confirmLabel: 'Apagar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await cubit.delete(project.id!);
    if (context.mounted) {
      showAppMessage(context, error ?? 'Projeto apagado.', isError: error != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projetos'), actions: const [ModeIndicatorChip()]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.text,
        onPressed: () => defineAndSearch(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo projeto'),
      ),
      body: BlocBuilder<ProjectsCubit, ListState<Project>>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'Não foi possível carregar os projetos',
              message: state.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: context.read<ProjectsCubit>().load,
            );
          }
          if (state.items.isEmpty) {
            // TEL15-E1
            return const EmptyState(
              icon: Icons.folder,
              title: 'Nenhum projeto ainda',
              message: 'Crie um projeto para guardar o local do set e repetir buscas.',
            );
          }
          return RefreshIndicator(
            onRefresh: context.read<ProjectsCubit>().load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final project = state.items[index];
                return _ProjectCard(
                  project: project,
                  onOpen: () => openResults(context, project.toCriteria()),
                  onEdit: () => defineAndSearch(context, initial: project.toCriteria()),
                  onDelete: () => _delete(context, project),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: SetIllustration(palette: SetPalette.fromSeed(project.name)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: theme.textTheme.titleMedium),
                    Text(project.subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final specialty in project.specialties)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções do projeto',
                onSelected: (value) => value == 'editar' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar e buscar')),
                  PopupMenuItem(value: 'apagar', child: Text('Apagar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
