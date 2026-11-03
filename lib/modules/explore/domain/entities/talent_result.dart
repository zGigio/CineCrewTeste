// =============================================================================
// modules/explore/domain/entities/talent_result.dart
// -----------------------------------------------------------------------------
// UM PROFISSIONAL NOS RESULTADOS (TEL12/TEL13).
//
// Repare: só há posição APROXIMADA e distância ARREDONDADA — é o que o
// banco devolve (a coordenada exata nunca chega ao app de quem busca).
// =============================================================================

import 'package:equatable/equatable.dart';

class TalentResult extends Equatable {
  final String id;
  final String name;
  final String? headline;
  final String? primaryRole;
  final List<String> secondarySkills;
  final String? avatarUrl;
  final double rating;
  final bool isAvailable;

  /// Posição aproximada (grade de ~1,1 km).
  final double approxLatitude;
  final double approxLongitude;

  /// Distância até o set, em km inteiros (mínimo 1).
  final double distanceKm;

  const TalentResult({
    required this.id,
    required this.name,
    required this.approxLatitude,
    required this.approxLongitude,
    required this.distanceKm,
    this.headline,
    this.primaryRole,
    this.secondarySkills = const [],
    this.avatarUrl,
    this.rating = 0,
    this.isAvailable = true,
  });

  /// Todas as especialidades, a principal primeiro.
  List<String> get specialties => [
        if (primaryRole != null && primaryRole!.isNotEmpty) primaryRole!,
        ...secondarySkills,
      ];

  /// "≈ 9 km do set"
  String get distanceLabel => '≈ ${distanceKm.round()} km do set';

  @override
  List<Object?> get props => [id, name, primaryRole, secondarySkills, distanceKm, isAvailable];
}
