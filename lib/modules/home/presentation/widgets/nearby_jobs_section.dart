// =============================================================================
// modules/home/presentation/widgets/nearby_jobs_section.dart
// -----------------------------------------------------------------------------
// SEÇÃO "VAGAS PERTO DE VOCÊ" da tela inicial (modo profissional).
//
// Faz uma busca espacial automática (raio de 50 km) a partir da localização
// salva no perfil e mostra as vagas em cartões horizontais, cada um com um
// mini mapa e o marcador do local — como as listas do Airbnb.
// Se o perfil ainda não tem localização, convida o usuário a definir.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/maps/map_preview.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/domain/entities/job_search_filter.dart';
import '../../../jobs/domain/usecases/search_jobs_usecase.dart';
import '../../../jobs/presentation/pages/job_detail_page.dart';
import '../../../profile/domain/entities/user_profile.dart';

class NearbyJobsSection extends StatefulWidget {
  final UserProfile profile;

  /// Ação do botão "Definir localização" (abre a aba Perfil).
  final VoidCallback onSetLocation;

  const NearbyJobsSection({
    super.key,
    required this.profile,
    required this.onSetLocation,
  });

  /// Raio usado na seção (em km).
  static const double radiusKm = 50;

  @override
  State<NearbyJobsSection> createState() => _NearbyJobsSectionState();
}

class _NearbyJobsSectionState extends State<NearbyJobsSection> {
  List<Job>? _jobs; // nulo = carregando
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recarrega se a localização do perfil mudar (ex.: salvou no Perfil).
  @override
  void didUpdateWidget(covariant NearbyJobsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.latitude != widget.profile.latitude ||
        oldWidget.profile.longitude != widget.profile.longitude) {
      _load();
    }
  }

  Future<void> _load() async {
    final profile = widget.profile;
    if (!profile.hasLocation) return;

    setState(() {
      _jobs = null;
      _error = null;
    });
    final result = await getIt<SearchJobsUseCase>()(
      JobSearchFilter(
        latitude: profile.latitude!,
        longitude: profile.longitude!,
        radiusKm: NearbyJobsSection.radiusKm,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      // Mostra no máximo 10 vagas na seção.
      (jobs) => setState(() => _jobs = jobs.take(10).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vagas perto de você',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Até ${NearbyJobsSection.radiusKm.round()} km do endereço do seu perfil',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    // Sem localização no perfil: convite para definir.
    if (!widget.profile.hasLocation) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.location_off_outlined),
          title: const Text('Defina sua localização'),
          subtitle: const Text('Assim mostramos as vagas mais próximas de você.'),
          trailing: TextButton(
            onPressed: widget.onSetLocation,
            child: const Text('Definir'),
          ),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off),
          title: Text(_error!),
          trailing: TextButton(onPressed: _load, child: const Text('Tentar de novo')),
        ),
      );
    }
    final jobs = _jobs;
    if (jobs == null) {
      return const SizedBox(height: 210, child: Center(child: CircularProgressIndicator()));
    }
    if (jobs.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.search_off),
          title: Text('Nenhuma vaga aberta por perto no momento.'),
          subtitle: Text('Use a aba "Buscar vagas" para aumentar o raio.'),
        ),
      );
    }

    // Cartões horizontais com mini mapa.
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _NearbyJobCard(job: jobs[index]),
      ),
    );
  }
}

/// Cartão compacto: mini mapa + título + função + cachê + distância.
class _NearbyJobCard extends StatelessWidget {
  final Job job;

  const _NearbyJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => JobDetailPage(job: job)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IgnorePointer: o toque passa para o cartão (o mapa não "rouba").
              IgnorePointer(
                child: MapPreview(latitude: job.latitude, longitude: job.longitude, height: 120),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(job.requiredRole, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Formatters.currency(job.fee),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (job.distanceInKm != null)
                          Text(
                            Formatters.distance(job.distanceInKm!),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
