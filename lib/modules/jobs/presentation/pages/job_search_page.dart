// =============================================================================
// modules/jobs/presentation/pages/job_search_page.dart
// -----------------------------------------------------------------------------
// TELA "BUSCAR VAGAS" (modo profissional), no estilo do Airbnb:
//
//   ( Onde | Quando | Função  [🔍] )
//   -------------------------------
//   [cartões das vagas encontradas, da mais próxima para a mais distante]
//
// Fluxo ao tocar na lupa:
//   1. define o ponto central (GPS ou endereço do perfil);
//   2. monta o filtro (raio, período, função);
//   3. o JobSearchCubit chama o caso de uso -> repositório -> PostGIS;
//   4. a lista é redesenhada com o resultado.
//
// O botão no topo alterna entre LISTA e MAPA. No mapa aparecem o círculo do
// raio pesquisado e o cachê de cada vaga como marcador (como no Airbnb).
// A tela também pode ser aberta já filtrada (ex.: tocando numa categoria
// da tela inicial), usando [initialRole] e [autoSearch].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/airbnb_search_bar.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/maps/radius_map.dart';
import '../../../../core/widgets/search_sheets.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_search_filter.dart';
import '../cubit/job_search_cubit.dart';
import '../widgets/job_card.dart';
import 'job_detail_page.dart';
import '../../../applications/presentation/pages/my_applications_page.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';

/// Parte "externa": cria o Cubit e o entrega para a parte visual.
class JobSearchPage extends StatelessWidget {
  /// Função já escolhida ao abrir a tela (ex.: categoria "Drone").
  final String? initialRole;

  /// Buscar automaticamente ao abrir a tela?
  final bool autoSearch;

  const JobSearchPage({super.key, this.initialRole, this.autoSearch = false});

  @override
  Widget build(BuildContext context) {
    // BlocProvider cria o cubit (via GetIt) e o fecha ao sair da tela.
    return BlocProvider(
      create: (_) => getIt<JobSearchCubit>(),
      child: _JobSearchView(initialRole: initialRole, autoSearch: autoSearch),
    );
  }
}

class _JobSearchView extends StatefulWidget {
  final String? initialRole;
  final bool autoSearch;

  const _JobSearchView({this.initialRole, this.autoSearch = false});

  @override
  State<_JobSearchView> createState() => _JobSearchViewState();
}

class _JobSearchViewState extends State<_JobSearchView> {
  /// ONDE: origem (GPS/perfil) e raio. Começa com GPS e 25 km.
  WhereChoice _where = const WhereChoice(origin: SearchOrigin.gps, radiusKm: 25);

  /// QUANDO: período escolhido no calendário (nulo = qualquer data).
  DateTimeRange? _dates;

  /// FUNÇÃO escolhida (nulo = qualquer função).
  String? _role;

  /// Obtendo a posição do GPS?
  bool _isLocating = false;

  /// Mostrar os resultados no MAPA (true) ou em LISTA (false)?
  bool _showMap = false;

  /// Centro e raio da última busca feita (usados para desenhar o mapa).
  LatLng? _lastCenter;
  double _lastRadiusKm = 25;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;

    if (widget.autoSearch) {
      // Se o perfil já tem localização, busca a partir dela (não precisa
      // pedir o GPS); senão, usa o GPS.
      final profile = context.read<SessionCubit>().state.profile;
      if (profile?.hasLocation ?? false) {
        _where = WhereChoice(origin: SearchOrigin.profile, radiusKm: _where.radiusKm);
      }
      // Espera a tela terminar de ser desenhada e então busca.
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  // ---------------------------------------------------------------------------
  // Textos exibidos em cada segmento da barra.
  // ---------------------------------------------------------------------------

  String get _whereText {
    final place = _where.origin == SearchOrigin.gps ? 'Perto de mim' : 'Meu endereço';
    return '$place · ${_where.radiusKm.round()} km';
  }

  String get _whenText => _dates == null
      ? 'Qualquer data'
      : '${Formatters.date(_dates!.start)} - ${Formatters.date(_dates!.end)}';

  String get _roleText => (_role == null || _role!.isEmpty) ? 'Qualquer função' : _role!;

  // ---------------------------------------------------------------------------
  // Escolhas da barra.
  // ---------------------------------------------------------------------------

  Future<void> _pickWhere() async {
    final profile = context.read<SessionCubit>().state.profile;
    final choice = await showWherePicker(
      context,
      current: _where,
      profileHasLocation: profile?.hasLocation ?? false,
    );
    if (choice != null) setState(() => _where = choice);
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    // Calendário de intervalo (data inicial e final), em português.
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Quando você está disponível?',
      saveText: 'Aplicar',
    );
    // Se o usuário cancelar, mantém o período atual.
    if (range != null) setState(() => _dates = range);
  }

  Future<void> _pickRole() async {
    final role = await showRolePicker(context, selected: _role);
    if (role != null) setState(() => _role = role.isEmpty ? null : role);
  }

  /// Limpa o período escolhido ("qualquer data").
  void _clearDates() => setState(() => _dates = null);

  // ---------------------------------------------------------------------------
  // Busca.
  // ---------------------------------------------------------------------------

  /// Descobre o ponto central da busca (latitude, longitude).
  /// Devolve `null` (e mostra o erro) se não for possível.
  Future<({double lat, double lng})?> _resolveCenter() async {
    if (_where.origin == SearchOrigin.profile) {
      final profile = context.read<SessionCubit>().state.profile;
      if (profile == null || !profile.hasLocation) {
        showAppMessage(context, 'Salve sua localização no perfil primeiro.', isError: true);
        return null;
      }
      return (lat: profile.latitude!, lng: profile.longitude!);
    }

    // Origem GPS: pede a posição atual ao serviço de localização.
    setState(() => _isLocating = true);
    final result = await getIt<LocationService>().getCurrentPosition();
    if (!mounted) return null;
    setState(() => _isLocating = false);

    return result.fold<({double lat, double lng})?>(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return null;
      },
      (position) => (lat: position.latitude, lng: position.longitude),
    );
  }

  Future<void> _search() async {
    final center = await _resolveCenter();
    if (center == null || !mounted) return;

    // Guarda o centro e o raio para desenhar o mapa de resultados.
    setState(() {
      _lastCenter = LatLng(center.lat, center.lng);
      _lastRadiusKm = _where.radiusKm;
    });

    // O período vai do INÍCIO do primeiro dia ao FIM do último dia.
    final from = _dates?.start;
    final to = _dates == null
        ? null
        : DateTime(_dates!.end.year, _dates!.end.month, _dates!.end.day, 23, 59, 59);

    await context.read<JobSearchCubit>().search(
          JobSearchFilter(
            latitude: center.lat,
            longitude: center.lng,
            radiusKm: _where.radiusKm,
            dateFrom: from,
            dateTo: to,
            role: _role,
          ),
        );
  }

  void _openJob(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JobDetailPage(job: job)),
    );
  }

  /// Mapa com o círculo do raio e um marcador de cachê para cada vaga.
  Widget _buildMap(List<Job> jobs) {
    return RadiusMap(
      center: _lastCenter!,
      radiusKm: _lastRadiusKm,
      markers: [
        for (final job in jobs)
          Marker(
            point: LatLng(job.latitude, job.longitude),
            width: 110,
            height: 30,
            child: LabelMarkerChip(
              // "R$ 1.500,00" -> "R$ 1.500" (mais curto para caber no mapa).
              label: Formatters.currency(job.fee).replaceAll(',00', ''),
              onTap: () => _openJob(job),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Interface.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar vagas'),
        actions: [
          // Alterna entre lista e mapa (só depois da primeira busca).
          if (_lastCenter != null)
            IconButton(
              tooltip: _showMap ? 'Ver em lista' : 'Ver no mapa',
              icon: Icon(_showMap ? Icons.view_list : Icons.map_outlined),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          // Atalho para as candidaturas (antes era uma aba própria).
          IconButton(
            tooltip: 'Minhas candidaturas',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MyApplicationsPage()),
            ),
          ),
          const ModeIndicatorChip(),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca estilo Airbnb.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: BlocBuilder<JobSearchCubit, ListState<Job>>(
              builder: (context, state) => AirbnbSearchBar(
                isLoading: _isLocating || state.isLoading,
                onSearch: _search,
                segments: [
                  SearchSegment(label: 'Onde', value: _whereText, onTap: _pickWhere),
                  SearchSegment(label: 'Quando', value: _whenText, onTap: _pickDates),
                  SearchSegment(label: 'Função', value: _roleText, onTap: _pickRole),
                ],
              ),
            ),
          ),
          // Atalho para limpar o período quando houver um escolhido.
          if (_dates != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: TextButton.icon(
                  onPressed: _clearDates,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Limpar datas'),
                ),
              ),
            ),
          // Resultado (ocupa o resto da tela).
          Expanded(
            child: BlocBuilder<JobSearchCubit, ListState<Job>>(
              builder: (context, state) {
                // Ainda não buscou nada.
                if (state.status == LoadStatus.initial) {
                  return const EmptyState(
                    icon: Icons.travel_explore,
                    title: 'Encontre trabalhos perto de você',
                    message: 'Escolha onde, quando e a função, e toque na lupa.',
                  );
                }
                // Primeira busca em andamento.
                if (state.isLoading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Erro.
                if (state.status == LoadStatus.failure) {
                  return EmptyState(
                    icon: Icons.cloud_off,
                    title: 'Não foi possível buscar',
                    message: state.errorMessage,
                    actionLabel: 'Tentar novamente',
                    onAction: _search,
                  );
                }
                // Nenhum resultado.
                if (state.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Nenhuma vaga encontrada',
                    message: 'Tente aumentar o raio, mudar as datas ou a função.',
                  );
                }
                // Resultado no MAPA.
                if (_showMap && _lastCenter != null) {
                  return _buildMap(state.items);
                }
                // Resultado em LISTA.
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // Primeiro item: contador de resultados.
                    if (index == 0) {
                      final count = state.items.length;
                      return Text(
                        count == 1 ? '1 vaga encontrada' : '$count vagas encontradas',
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    }
                    final job = state.items[index - 1];
                    return JobCard(job: job, onTap: () => _openJob(job));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
