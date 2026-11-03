// =============================================================================
// modules/jobs/domain/entities/job.dart
// -----------------------------------------------------------------------------
// ENTIDADE VAGA (camada de DOMÍNIO).
//
// Uma vaga é uma oportunidade de trabalho publicada por um CONTRATANTE,
// com as três informações da busca no estilo Airbnb:
//   ONDE   -> latitude/longitude (+ endereço)
//   QUANDO -> início e fim do trabalho
//   QUEM   -> a função procurada (ex.: Videomaker)
// =============================================================================

import 'package:equatable/equatable.dart';

/// Situação da vaga.
enum JobStatus {
  open('aberta', 'Aberta'),
  closed('encerrada', 'Encerrada');

  const JobStatus(this.value, this.label);

  /// Valor gravado no banco.
  final String value;

  /// Texto exibido na tela.
  final String label;

  /// Converte o texto do banco no enum (padrão: aberta).
  static JobStatus fromValue(String? value) => JobStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => JobStatus.open,
      );
}

/// Vaga de trabalho do audiovisual.
class Job extends Equatable {
  final String id;

  /// Quem publicou (contratante).
  final String recruiterId;
  final String? recruiterName;
  final String? recruiterAvatarUrl;

  /// O QUE: título, descrição, função procurada e cachê.
  final String title;
  final String description;
  final String requiredRole;
  final double fee;

  /// QUANDO: período do trabalho.
  final DateTime startsAt;
  final DateTime endsAt;

  /// ONDE: endereço e coordenadas.
  final String? address;
  final String? city;
  final String? state;
  final double latitude;
  final double longitude;

  final JobStatus status;

  /// Distância até o ponto da busca (calculada pelo PostGIS).
  /// Só existe nos resultados da busca espacial.
  final double? distanceInKm;

  final DateTime? createdAt;

  const Job({
    required this.id,
    required this.recruiterId,
    this.recruiterName,
    this.recruiterAvatarUrl,
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
    this.status = JobStatus.open,
    this.distanceInKm,
    this.createdAt,
  });

  /// A vaga ainda aceita candidaturas?
  bool get isOpen => status == JobStatus.open;

  /// "Cidade - UF" para exibir nos cartões.
  String get locationLabel => [city, state]
      .where((part) => part != null && part.isNotEmpty)
      .join(' - ');

  @override
  List<Object?> get props => [
        id,
        recruiterId,
        recruiterName,
        recruiterAvatarUrl,
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
        status,
        distanceInKm,
        createdAt,
      ];
}
