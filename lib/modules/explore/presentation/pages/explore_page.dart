// =============================================================================
// modules/explore/presentation/pages/explore_page.dart
// -----------------------------------------------------------------------------
// TEL10 — EXPLORAR (início do modo Contratar).
//
//   Olá, Leonardo
//   Para onde vai a próxima produção?
//   ┌──────────────────────────────────┐
//   │ 📍 Onde é o set?   Definir local │
//   │ ☰  Especialidades  Qualquer...   │
//   │ ⚙  Raio de busca   Definir em km │
//   └──────────────────────────────────┘
//   [🔍 Buscar profissionais]          <- destaque âmbar
//   PROJETOS RECENTES  (só se houver projetos salvos)
//
// Extra do app (fora da documentação): atalho "Publicar uma vaga".
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/list_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/set_illustration.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../home/presentation/widgets/recruiter_quick_actions.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/search_criteria.dart';
import '../../domain/search_rules.dart';
import '../cubit/projects_cubit.dart';
import '../explore_navigation.dart';

class ExplorePage extends StatefulWidget {
  /// Chamado depois que uma vaga é publicada pelo atalho (extra).
  final VoidCallback onJobCreated;

  const ExplorePage({super.key, required this.onJobCreated});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  /// Rascunho da busca montado pelas três linhas do cartão.
  SearchCriteria _draft = const SearchCriteria();

  /// Alguma linha foi tocada? (antes disso, o raio mostra "Definir em km")
  bool _radiusTouched = false;

  /// Qualquer linha abre a TEL11 com o rascunho; ao confirmar, já busca.
  Future<void> _defineSearch({bool validateOnOpen = false}) async {
    final criteria = await openDefineSearch(
      context,
      initial: _draft,
      validateOnOpen: validateOnOpen,
    );
    if (criteria == null || !mounted) return;
    setState(() {
      _draft = criteria;
      _radiusTouched = true;
    });
    await openResults(context, criteria);
  }

  /// "Buscar profissionais": com tudo preenchido busca direto; senão abre a
  /// TEL11 já mostrando o que falta (TEL11-E1).
  Future<void> _search() async {
    if (SearchRules.validate(_draft).isEmpty) {
      await openResults(context, _draft);
    } else {
      await _defineSearch(validateOnOpen: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<SessionCubit>().state.profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: const [NotificationBell(), ModeIndicatorChip()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [
          Text(
            'Olá, ${profile.firstName}',
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          Text('Para onde vai a próxima produção?', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),

          // ---- Cartão de busca com três linhas --------------------------------
          Card(
            elevation: 3,
            child: Column(
              children: [
                _SearchRow(
                  icon: Icons.place,
                  iconColor: AppColors.error,
                  label: 'Onde é o set?',
                  value: _draft.place == null ? 'Definir local' : _draft.placeLabel,
                  onTap: _defineSearch,
                ),
                const Divider(height: 1, indent: 52),
                _SearchRow(
                  icon: Icons.list,
                  label: 'Especialidades',
                  value: _draft.specialties.isEmpty
                      ? 'Qualquer especialidade'
                      : _draft.specialties.join(', '),
                  onTap: _defineSearch,
                ),
                const Divider(height: 1, indent: 52),
                _SearchRow(
                  icon: Icons.tune,
                  label: 'Raio de busca',
                  value: _radiusTouched ? '${_draft.radiusKm} km' : 'Definir em km',
                  onTap: _defineSearch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: AppTheme.highlightButton,
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text('Buscar profissionais'),
          ),
          const SizedBox(height: 24),

          // ---- Projetos recentes (só se existirem) -----------------------------
          BlocBuilder<ProjectsCubit, ListState<Project>>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJETOS RECENTES', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.items.length.clamp(0, 6),
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final project = state.items[index];
                        return _RecentProjectCard(
                          project: project,
                          onTap: () => openResults(context, project.toCriteria()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // ---- Extra: publicar vaga --------------------------------------------
          Text('TAMBÉM NO CINECREW', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          RecruiterQuickActions(onJobCreated: widget.onJobCreated),
        ],
      ),
    );
  }
}

/// Uma linha do cartão de busca: ícone + rótulo pequeno + valor.
class _SearchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SearchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura de projeto recente: ilustração + nome + "Cidade · raio".
class _RecentProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _RecentProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: SizedBox(
                height: 92,
                width: 140,
                child: SetIllustration(palette: SetPalette.fromSeed(project.name)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${project.place.city ?? project.place.label} · ${project.radiusKm} km',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
