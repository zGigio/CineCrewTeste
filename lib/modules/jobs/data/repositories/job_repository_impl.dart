// =============================================================================
// modules/jobs/data/repositories/job_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do repositório de vagas usando o SUPABASE.
//
//   * Busca espacial -> função SQL `search_jobs` (PostGIS), chamada via RPC;
//   * Demais operações -> tabela `jobs`.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_draft.dart';
import '../../domain/entities/job_search_filter.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_model.dart';

@LazySingleton(as: JobRepository)
class JobRepositoryImpl implements JobRepository {
  static const String _table = 'jobs';

  /// Colunas buscadas no SELECT, incluindo o nome e a foto do contratante.
  /// "recruiter:profiles!jobs_recruiter_id_fkey(...)" significa: traga os
  /// dados da tabela `profiles` ligada pela chave estrangeira
  /// `jobs_recruiter_id_fkey` e chame esse bloco de "recruiter".
  static const String _selectWithRecruiter =
      '*, recruiter:profiles!jobs_recruiter_id_fkey(full_name, avatar_url)';

  final SupabaseClient _client;

  JobRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Job>>> searchJobs(JobSearchFilter filter) {
    return guardRequest<List<Job>>(() async {
      // Os nomes dos parâmetros precisam ser IGUAIS aos da função SQL.
      final response = await _client.rpc(
        'search_jobs',
        params: {
          'p_lat': filter.latitude,
          'p_lng': filter.longitude,
          'p_radius_km': filter.radiusKm,
          'p_role': (filter.role == null || filter.role!.isEmpty) ? null : filter.role,
          'p_date_from': filter.dateFrom?.toUtc().toIso8601String(),
          'p_date_to': filter.dateTo?.toUtc().toIso8601String(),
        },
      );
      final rows = response as List<dynamic>;
      return rows
          .map((row) => JobModel.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Either<Failure, List<Job>>> getRecruiterJobs(String recruiterId) {
    return guardRequest<List<Job>>(() async {
      // SELECT ... WHERE recruiter_id = ? ORDER BY starts_at DESC
      final rows = await _client
          .from(_table)
          .select(_selectWithRecruiter)
          .eq('recruiter_id', recruiterId)
          .order('starts_at', ascending: false);
      return rows.map(JobModel.fromJson).toList();
    });
  }

  @override
  Future<Either<Failure, Job>> createJob(JobDraft draft) {
    return guardRequest<Job>(() async {
      // INSERT e já devolve a linha criada (com id e data de criação).
      final row = await _client
          .from(_table)
          .insert(JobModel.draftToJson(draft))
          .select(_selectWithRecruiter)
          .single();
      return JobModel.fromJson(row);
    });
  }

  @override
  Future<Either<Failure, Unit>> updateJobStatus(String jobId, JobStatus status) {
    return guardRequest<Unit>(() async {
      await _client.from(_table).update({'status': status.value}).eq('id', jobId);
      return unit;
    });
  }
}
