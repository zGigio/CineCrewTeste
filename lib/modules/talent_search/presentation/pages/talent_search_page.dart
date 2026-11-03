// =============================================================================
// modules/talent_search/presentation/pages/talent_search_page.dart
// -----------------------------------------------------------------------------
// TELA "TALENTOS PERTO DO SET" (modo contratante).
//
// O contratante escolhe ONDE (GPS ou endereço do perfil + raio) e a FUNÇÃO,
// e vê os profissionais encontrados:
//   - no MAPA: círculo do raio + um marcador com o nome de cada profissional;
//   - em LISTA: foto, função, distância e disponibilidade.
// Tocar em um profissional abre o perfil público (com o currículo).
//
// Por trás, a função SQL `search_professionals` usa o PostGIS
// (ST_DWithin + ST_Distance) — o núcleo de computação espacial do TCC.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/role_icons.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/presentation/list_state.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/airbnb_search_bar.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/maps/radius_map.dart';
import '../../../../core/widgets/search_sheets.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/usecases/search_talents_by_radius_usecase.dart';
import '../cubit/talent_search_cubit.dart';

class TalentSearchPage extends StatelessWidget {
  const TalentSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TalentSearchCubit>(),
      child: const _TalentSearchView(),
    );
  }
}

class _TalentSearchView extends StatefulWidget {
  const _TalentSearchView();

  @override
  State<_TalentSearchView> createState() => _TalentSearchViewState();
}

class _TalentSearchViewState extends State<_TalentSearchView> {
  WhereChoice _where = const WhereChoice(origin: SearchOrigin.gps, radiusKm: 25);
  String? _role;
  bool _isLocating = false;

  /// Começa no MAPA: é a visão mais interessante para o contratante.
  bool _showMap = true;

  LatLng? _lastCenter;
  double _lastRadiusKm = 25;

  @override
  void initState() {
    super.initState();
    // Se o perfil tem localização, já começa buscando a partir dela.
    final profile = context.read<SessionCubit>().state.profile;
    if (profile?.hasLocation ?? false) {
      _where = WhereChoice(origin: SearchOrigin.profile, radiusKm: _where.radiusKm);
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  String get _whereText {
    final place = _where.origin == SearchOrigin.gps ? 'Perto de mim' : 'Meu endereço';
    return '$place · ${_where.radiusKm.round()} km';
  }

  String get _roleText => _role ?? 'Qualquer função';

  Future<void> _pickWhere() async {
    final profile = context.read<SessionCubit>().state.profile;
    final choice = await showWherePicker(
      context,
      current: _where,
      profileHasLocation: profile?.hasLocation ?? false,
    );
    if (choice != null) setState(() => _where = choice);
  }

  Future<void> _pickRole() async {
    final role = await showRolePicker(context, selected: _role);
    if (role != null) setState(() => _role = role.isEmpty ? null : role);
  }

  /// Ponto central da busca (perfil ou GPS).
  Future<LatLng?> _resolveCenter() async {
    if (_where.origin == SearchOrigin.profile) {
      final profile = context.read<SessionCubit>().state.profile;
      if (profile == null || !profile.hasLocation) {
        showAppMessage(context, 'Salve sua localização no perfil primeiro.', isError: true);
        return null;
      }
      return LatLng(profile.latitude!, profile.longitude!);
    }

    setState(() => _isLocating = true);
    final result = await getIt<LocationService>().getCurrentPosition();
    if (!mounted) return null;
    setState(() => _isLocating = false);

    return result.fold<LatLng?>(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return null;
      },
      (position) => LatLng(position.latitude, position.longitude),
    );
  }

  Future<void> _search() async {
    final center = await _resolveCenter();
    if (center == null || !mounted) return;

    setState(() {
      _lastCenter = center;
      _lastRadiusKm = _where.radiusKm;
    });

    await context.read<TalentSearchCubit>().search(
          SearchParams(
            latitude: center.latitude,
            longitude: center.longitude,
            radiusInKm: _where.radiusKm,
            skill: _role,
          ),
        );
  }

  void _openProfile(ProfessionalEntity professional) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PublicProfilePage(userId: professional.id)),
    );
  }

  /// Mapa: círculo do raio + marcador com o primeiro nome de cada profissional.
  Widget _buildMap(List<ProfessionalEntity> professionals) {
    return RadiusMap(
      center: _lastCenter!,
      radiusKm: _lastRadiusKm,
      markers: [
        for (final professional in professionals)
          Marker(
            point: LatLng(
              professional.location.latitude,
              professional.location.longitude,
            ),
            width: 120,
            height: 30,
            child: LabelMarkerChip(
              label: professional.name.split(' ').first,
              icon: iconForRole(professional.primaryRole),
              onTap: () => _openProfile(professional),
            ),
          ),
      ],
    );
  }

  /// Lista: um cartão por profissional, do mais próximo ao mais distante.
  Widget _buildList(List<ProfessionalEntity> professionals) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: professionals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final professional = professionals[index];
        return Card(
          child: ListTile(
            onTap: () => _openProfile(professional),
            leading: UserAvatar(imageUrl: professional.avatarUrl, name: professional.name),
            title: Text(professional.name),
            subtitle: Text(
              [
                if (professional.primaryRole.isNotEmpty) professional.primaryRole,
                if (professional.rating > 0)
                  '★ ${professional.rating.toStringAsFixed(1).replaceAll('.', ',')}',
                if (professional.distanceInKm != null)
                  'a ${Formatters.distance(professional.distanceInKm!)}',
              ].join(' · '),
            ),
            trailing: Icon(
              professional.isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
              color: professional.isAvailable ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talentos perto do set'),
        actions: [
          if (_lastCenter != null)
            IconButton(
              tooltip: _showMap ? 'Ver em lista' : 'Ver no mapa',
              icon: Icon(_showMap ? Icons.view_list : Icons.map_outlined),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: BlocBuilder<TalentSearchCubit, ListState<ProfessionalEntity>>(
              builder: (context, state) => AirbnbSearchBar(
                isLoading: _isLocating || state.isLoading,
                onSearch: _search,
                segments: [
                  SearchSegment(label: 'Onde', value: _whereText, onTap: _pickWhere),
                  SearchSegment(label: 'Função', value: _roleText, onTap: _pickRole),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<TalentSearchCubit, ListState<ProfessionalEntity>>(
              builder: (context, state) {
                if (state.status == LoadStatus.initial) {
                  return const EmptyState(
                    icon: Icons.person_search,
                    title: 'Encontre profissionais perto do set',
                    message: 'Escolha onde e a função, e toque na lupa.',
                  );
                }
                if (state.isLoading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == LoadStatus.failure) {
                  return EmptyState(
                    icon: Icons.cloud_off,
                    title: 'Não foi possível buscar',
                    message: state.errorMessage,
                    actionLabel: 'Tentar novamente',
                    onAction: _search,
                  );
                }
                if (state.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Nenhum profissional encontrado',
                    message: 'Tente aumentar o raio ou escolher outra função.',
                  );
                }
                return _showMap ? _buildMap(state.items) : _buildList(state.items);
              },
            ),
          ),
        ],
      ),
    );
  }
}
