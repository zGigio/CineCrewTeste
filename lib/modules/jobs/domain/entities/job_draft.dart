// =============================================================================
// modules/jobs/domain/entities/job_draft.dart
// -----------------------------------------------------------------------------
// RASCUNHO DE VAGA: os dados preenchidos no formulário de publicação.
//
// É diferente de [Job] porque ainda NÃO existe no banco: não tem id, data de
// criação nem distância. Só depois de gravada é que vira um [Job].
// =============================================================================

import 'package:equatable/equatable.dart';

class JobDraft extends Equatable {
  final String recruiterId;
  final String title;
  final String description;
  final String requiredRole;
  final double fee;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? address;
  final String? city;
  final String? state;
  final double latitude;
  final double longitude;

  const JobDraft({
    required this.recruiterId,
    required this.title,
    required this.description,
    required this.requiredRole,
    required this.fee,
    required this.startsAt,
    required this.endsAt,
    this.address,
    this.city,
    this.state,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
        recruiterId,
        title,
        description,
        requiredRole,
        fee,
        startsAt,
        endsAt,
        address,
        city,
        state,
        latitude,
        longitude,
      ];
}
