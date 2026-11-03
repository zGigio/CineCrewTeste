// =============================================================================
// modules/explore/presentation/pages/results_page.dart
// -----------------------------------------------------------------------------
// TEL12 (LISTA) e TEL13 (MAPA) — RESULTADOS DA BUSCA de profissionais.
//
//   [📍 Petrolina · PE / Raio 50 km · 2 especialidades     (Filtros)]
//   4 profissionais · ordenados por distância
//   [cartões...]                                   ( 🗺 Mapa )  <- flutuante
//
// No mapa: círculo do raio, pino vermelho no set, balões "≈ N km" na
// POSIÇÃO APROXIMADA de cada profissional, aviso de privacidade e o cartão
// do selecionado com "Ver perfil".
//
// Estados: TEL12-E1 carregando (esqueleto) · TEL12-E2 nenhum profissional ·
//          TEL12-E3 erro de conexão · TEL12-E4 painel de filtros.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/maps/radius_map.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../../domain/entities/search_criteria.dart';
import '../../domain/entities/talent_result.dart';
import '../cubit/talent_results_cubit.dart';
import '../explore_navigation.dart';
import '../widgets/distance_balloon.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/search_summary_pill.dart';
import '../widgets/talent_result_card.dart';

class ResultsPage extends StatelessWidget {
  final SearchCriteria criteria;

  const ResultsPage({super.key, required this.criteria});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TalentResultsCubit>()..search(criteria),
      child: const _ResultsView(),
    );
  }
}

class _ResultsView extends StatefulWidget {
  const _ResultsView();

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView> {
  bool _showMap = false;

  TalentResultsCubit get _cubit => context.read<TalentResultsCubit>();

  /// Tocar no resumo: edita a busca (TEL11) e refaz.
  Future<void> _editSearch() async {
    final criteria = await openDefineSearch(context, initial: _cubit.state.criteria);
    if (criteria != null && mounted) await _cubit.search(criteria);
  }

  /// Painel de filtros (TEL12-E4).
  Future<void> _openFilters() async {
    final criteria = await showFiltersSheet(context, _cubit.state.criteria);
    if (criteria != null && mounted) await _cubit.search(criteria);
  }

  void _openProfile(TalentResult talent) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfilePage(
          userId: talent.id,
          // TEL14: "≈ 9 km do set · localização aproximada".
          distanceLabel: talent.distanceLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TalentResultsCubit, TalentResultsState>(
      builder: (context, state) {
        final hasResults = state.status == ResultsStatus.success && state.results.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados'),
            actions: const [ModeIndicatorChip()],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchSummaryPill(
                  criteria: state.criteria,
                  onEdit: _editSearch,
                  onFilters: _openFilters,
                ),
              ),
              Expanded(child: _buildContent(state)),
            ],
          ),
          // Botão flutuante em pílula: alterna lista <-> mapa.
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: hasResults
              ? FloatingActionButton.extended(
                  onPressed: () => setState(() => _showMap = !_showMap),
                  icon: Icon(_showMap ? Icons.list : Icons.map),
                  label: Text(_showMap ? 'Lista' : 'Mapa'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildContent(TalentResultsState state) {
    // "switch expression": um widget para cada situação.
    return switch (state.status) {
      // TEL12-E1: esqueleto no formato dos cartões.
      ResultsStatus.loading => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: const [TalentResultSkeleton(), TalentResultSkeleton()],
        ),
      // TEL12-E3: erro de conexão; a busca é mantida.
      ResultsStatus.failure => EmptyState(
          icon: Icons.warning_rounded,
          title: 'Não foi possível buscar',
          message: '${state.errorMessage ?? 'Verifique sua conexão e tente novamente.'} '
              'Sua busca foi mantida.',
          actionLabel: 'Tentar novamente',
          onAction: _cubit.retry,
        ),
      // TEL12-E2: ninguém compatível dentro do raio.
      ResultsStatus.success when state.results.isEmpty => EmptyState(
          icon: Icons.search,
          title: 'Nenhum profissional encontrado',
          message: 'Não há profissionais compatíveis dentro de ${state.criteria.radiusKm} km. '
              'Você pode alterar o raio ou as especialidades.',
          actionLabel: 'Alterar busca',
          onAction: _openFilters,
        ),
      ResultsStatus.success => _showMap ? _buildMap(state) : _buildList(state),
    };
  }

  // ---- TEL12: LISTA -----------------------------------------------------------
  Widget _buildList(TalentResultsState state) {
    final count = state.results.length;
    return ListView(
      // Espaço embaixo para o botão flutuante não cobrir o último cartão.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Text(
          '$count ${count == 1 ? 'profissional' : 'profissionais'} · ordenados por distância',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final talent in state.results)
          TalentResultCard(talent: talent, onTap: () => _openProfile(talent)),
      ],
    );
  }

  // ---- TEL13: MAPA ------------------------------------------------------------
  Widget _buildMap(TalentResultsState state) {
    final place = state.criteria.place!;
    final selected = state.selected;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: RadiusMap(
              center: LatLng(place.latitude, place.longitude),
              radiusKm: state.criteria.radiusKm.toDouble(),
              centerPin: true,
              markers: [
                for (final talent in state.results)
                  Marker(
                    point: LatLng(talent.approxLatitude, talent.approxLongitude),
                    width: 76,
                    height: 34,
                    child: DistanceBalloon(
                      label: '≈ ${talent.distanceKm.round()} km',
                      selected: talent.id == state.selectedId,
                      onTap: () => _cubit.select(talent.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const AppBanner.info('Posições aproximadas, para proteger a privacidade.'),
        const SizedBox(height: 12),
        if (selected != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  UserAvatar(imageUrl: selected.avatarUrl, name: selected.name, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selected.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          [
                            if (selected.specialties.isNotEmpty) selected.specialties.first,
                            selected.distanceLabel,
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _openProfile(selected),
                    child: const Text('Ver perfil'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
