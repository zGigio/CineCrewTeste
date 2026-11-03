// =============================================================================
// modules/jobs/domain/entities/job_search_filter.dart
// -----------------------------------------------------------------------------
// FILTRO DA BUSCA DE VAGAS (Onde + Quando + Função), como no Airbnb.
// =============================================================================

import 'package:equatable/equatable.dart';

class JobSearchFilter extends Equatable {
  /// ONDE: ponto central da busca e raio em quilômetros.
  final double latitude;
  final double longitude;
  final double radiusKm;

  /// QUANDO: período desejado (opcional). Uma vaga aparece se o período
  /// dela tiver ALGUM dia em comum com o período buscado.
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// FUNÇÃO procurada (opcional; nulo = qualquer função).
  final String? role;

  const JobSearchFilter({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.dateFrom,
    this.dateTo,
    this.role,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm, dateFrom, dateTo, role];
}
