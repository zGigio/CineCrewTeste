// =============================================================================
// modules/explore/domain/entities/project.dart
// -----------------------------------------------------------------------------
// PROJETO do contratante (TEL15): nome + local do set + raio + especialidades.
// Serve para repetir a busca depois, sem preencher tudo de novo (P13).
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../../../core/services/geocoding/geo_place.dart';
import 'search_criteria.dart';

class Project extends Equatable {
  /// `null` = projeto novo (ainda não salvo).
  final String? id;
  final String name;
  final GeoPlace place;
  final int radiusKm;
  final List<String> specialties;
  final DateTime? updatedAt;

  const Project({
    this.id,
    required this.name,
    required this.place,
    required this.radiusKm,
    required this.specialties,
    this.updatedAt,
  });

  /// Critérios de busca a partir do projeto.
  SearchCriteria toCriteria() => SearchCriteria(
        place: place,
        specialties: specialties,
        radiusKm: radiusKm,
        projectId: id,
        projectName: name,
      );

  /// "Petrolina · PE · raio 50 km"
  String get subtitle {
    final cityState = [place.city, place.state].whereType<String>().join(' · ');
    return '${cityState.isEmpty ? place.label : cityState} · raio $radiusKm km';
  }

  @override
  List<Object?> get props => [id, name, place, radiusKm, specialties, updatedAt];
}
