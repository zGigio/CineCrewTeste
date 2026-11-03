// =============================================================================
// modules/jobs/data/models/job_model.dart
// -----------------------------------------------------------------------------
// MODEL da vaga: conversão entre o JSON do Supabase e a entidade [Job].
//
// O JSON pode chegar em dois formatos:
//   1. da função de busca `search_jobs`: o nome do contratante vem em
//      `recruiter_name` (campo "achatado");
//   2. de um SELECT com junção: os dados do contratante vêm aninhados em
//      `recruiter: { full_name, avatar_url }`.
// O fromJson aceita os dois.
// =============================================================================

import '../../domain/entities/job.dart';
import '../../domain/entities/job_draft.dart';

class JobModel extends Job {
  const JobModel({
    required super.id,
    required super.recruiterId,
    super.recruiterName,
    super.recruiterAvatarUrl,
    required super.title,
    required super.description,
    required super.requiredRole,
    required super.fee,
    required super.startsAt,
    required super.endsAt,
    super.address,
    super.city,
    super.state,
    required super.latitude,
    required super.longitude,
    super.status,
    super.distanceInKm,
    super.createdAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Dados do contratante no formato aninhado (pode não existir).
    final recruiter = json['recruiter'] as Map<String, dynamic>?;

    return JobModel(
      id: json['id'] as String,
      recruiterId: json['recruiter_id'] as String,
      recruiterName: (json['recruiter_name'] as String?) ??
          (recruiter?['full_name'] as String?),
      recruiterAvatarUrl: (json['recruiter_avatar_url'] as String?) ??
          (recruiter?['avatar_url'] as String?),
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      requiredRole: json['required_role'] as String,
      fee: (json['fee'] as num).toDouble(),
      // O banco guarda datas em UTC (horário universal); `.toLocal()`
      // converte para o fuso do celular (ex.: horário de Brasília).
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: JobStatus.fromValue(json['status'] as String?),
      distanceInKm: (json['distance_in_km'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
    );
  }

  /// JSON para INSERIR uma vaga nova a partir do rascunho.
  /// As datas vão em UTC e no formato ISO 8601 (padrão internacional).
  static Map<String, dynamic> draftToJson(JobDraft draft) {
    return {
      'recruiter_id': draft.recruiterId,
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'required_role': draft.requiredRole,
      'fee': draft.fee,
      'starts_at': draft.startsAt.toUtc().toIso8601String(),
      'ends_at': draft.endsAt.toUtc().toIso8601String(),
      'address': _emptyToNull(draft.address),
      'city': _emptyToNull(draft.city),
      'state': _emptyToNull(draft.state),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    };
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
