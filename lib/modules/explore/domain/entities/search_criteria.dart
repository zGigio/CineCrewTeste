// =============================================================================
// modules/explore/domain/entities/search_criteria.dart
// -----------------------------------------------------------------------------
// CRITÉRIOS DA BUSCA de profissionais (TEL11 e painel de filtros TEL12-E4):
//   ONDE (local do set) + QUAIS especialidades + RAIO + só disponíveis.
// Também guarda o projeto de origem (se a busca veio de um projeto salvo).
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../../../core/services/geocoding/geo_place.dart';

/// Regras do raio (decisão P05 da documentação).
class RadiusRules {
  RadiusRules._();

  static const int min = 1;
  static const int max = 200;
  static const int defaultKm = 50;
}

class SearchCriteria extends Equatable {
  /// Local do set (`null` = ainda não definido).
  final GeoPlace? place;
  final List<String> specialties;
  final int radiusKm;

  /// Filtro "Somente disponíveis" (TEL12-E4).
  final bool onlyAvailable;

  /// Projeto de onde a busca veio (opcional).
  final String? projectId;
  final String? projectName;

  const SearchCriteria({
    this.place,
    this.specialties = const [],
    this.radiusKm = RadiusRules.defaultKm,
    this.onlyAvailable = false,
    this.projectId,
    this.projectName,
  });

  /// Resumo da pílula: "Raio 50 km · 2 especialidades".
  String get summary {
    final count = specialties.length;
    final what = count == 0
        ? 'qualquer especialidade'
        : count == 1
            ? specialties.first
            : '$count especialidades';
    return 'Raio $radiusKm km · $what';
  }

  /// Local resumido: "Petrolina · PE" (ou o rótulo do ponto).
  String get placeLabel {
    final place = this.place;
    if (place == null) return 'Definir local';
    final cityState = [place.city, place.state].whereType<String>().join(' · ');
    return cityState.isEmpty ? place.label : cityState;
  }

  SearchCriteria copyWith({
    GeoPlace? place,
    List<String>? specialties,
    int? radiusKm,
    bool? onlyAvailable,
    String? projectId,
    String? projectName,
  }) {
    return SearchCriteria(
      place: place ?? this.place,
      specialties: specialties ?? this.specialties,
      radiusKm: radiusKm ?? this.radiusKm,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
    );
  }

  @override
  List<Object?> get props =>
      [place, specialties, radiusKm, onlyAvailable, projectId, projectName];
}
