// =============================================================================
// modules/applications/data/models/job_application_model.dart
// -----------------------------------------------------------------------------
// MODEL da candidatura: converte o JSON do Supabase em [JobApplication].
//
// Dependendo da consulta, o JSON traz junto (aninhado):
//   - `job`: os dados da vaga (visão do profissional);
//   - `professional`: o perfil do candidato (visão do contratante).
// =============================================================================

import '../../../jobs/data/models/job_model.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../domain/entities/job_application.dart';

class JobApplicationModel extends JobApplication {
  const JobApplicationModel({
    required super.id,
    required super.jobId,
    required super.professionalId,
    super.coverMessage,
    required super.status,
    required super.createdAt,
    super.job,
    super.professional,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    final jobJson = json['job'] as Map<String, dynamic>?;
    final professionalJson = json['professional'] as Map<String, dynamic>?;

    return JobApplicationModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      professionalId: json['professional_id'] as String,
      coverMessage: json['cover_message'] as String?,
      status: ApplicationStatus.fromValue(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      // Só converte o bloco aninhado se ele veio na consulta.
      job: jobJson != null ? JobModel.fromJson(jobJson) : null,
      professional:
          professionalJson != null ? UserProfileModel.fromJson(professionalJson) : null,
    );
  }
}
