// =============================================================================
// modules/applications/data/repositories/application_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do repositório de candidaturas (tabela `job_applications`).
//
// Usa "junções" do PostgREST para trazer, numa única consulta, a candidatura
// junto com a vaga ou com o perfil do candidato. O trecho depois do "!" é o
// nome da chave estrangeira usada na ligação (definida no schema.sql).
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../models/job_application_model.dart';
import '../../../profile/data/profile_columns.dart';

@LazySingleton(as: ApplicationRepository)
class ApplicationRepositoryImpl implements ApplicationRepository {
  static const String _table = 'job_applications';

  /// Candidatura + vaga + nome/foto de quem publicou a vaga.
  static const String _selectWithJob =
      '*, job:jobs!job_applications_job_id_fkey('
      '*, recruiter:profiles!jobs_recruiter_id_fkey(full_name, avatar_url))';

  /// Candidatura + perfil completo do candidato.
  static const String _selectWithProfessional =
      '*, professional:profiles!job_applications_professional_id_fkey(${ProfileColumns.public})';

  final SupabaseClient _client;

  ApplicationRepositoryImpl(this._client);

  @override
  Future<Either<Failure, JobApplication>> apply({
    required String jobId,
    required String professionalId,
    String? coverMessage,
  }) {
    return guardRequest<JobApplication>(() async {
      final row = await _client
          .from(_table)
          .insert({
            'job_id': jobId,
            'professional_id': professionalId,
            'cover_message': coverMessage,
          })
          .select()
          .single();
      return JobApplicationModel.fromJson(row);
    });
  }

  @override
  Future<Either<Failure, List<JobApplication>>> getMyApplications(
    String professionalId,
  ) {
    return guardRequest<List<JobApplication>>(() async {
      final rows = await _client
          .from(_table)
          .select(_selectWithJob)
          .eq('professional_id', professionalId)
          .order('created_at', ascending: false); // mais recentes primeiro
      return rows.map(JobApplicationModel.fromJson).toList();
    });
  }

  @override
  Future<Either<Failure, List<JobApplication>>> getApplicationsForJob(String jobId) {
    return guardRequest<List<JobApplication>>(() async {
      final rows = await _client
          .from(_table)
          .select(_selectWithProfessional)
          .eq('job_id', jobId)
          .order('created_at'); // por ordem de chegada
      return rows.map(JobApplicationModel.fromJson).toList();
    });
  }

  @override
  Future<Either<Failure, JobApplication?>> findApplication({
    required String jobId,
    required String professionalId,
  }) {
    return guardRequest<JobApplication?>(() async {
      // maybeSingle: devolve null (em vez de erro) se não houver linha.
      final row = await _client
          .from(_table)
          .select()
          .eq('job_id', jobId)
          .eq('professional_id', professionalId)
          .maybeSingle();
      return row == null ? null : JobApplicationModel.fromJson(row);
    });
  }

  @override
  Future<Either<Failure, Unit>> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) {
    return guardRequest<Unit>(() async {
      await _client
          .from(_table)
          .update({'status': status.value})
          .eq('id', applicationId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> cancel(String applicationId) {
    return guardRequest<Unit>(() async {
      await _client.from(_table).delete().eq('id', applicationId);
      return unit;
    });
  }
}
