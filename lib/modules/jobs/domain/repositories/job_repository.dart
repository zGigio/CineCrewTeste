// =============================================================================
// modules/jobs/domain/repositories/job_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do repositório de VAGAS (camada de DOMÍNIO).
// =============================================================================

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/job.dart';
import '../entities/job_draft.dart';
import '../entities/job_search_filter.dart';

abstract class JobRepository {
  /// BUSCA ESPACIAL de vagas abertas (Onde + Quando + Função).
  /// O resultado vem ordenado da mais próxima para a mais distante.
  Future<Either<Failure, List<Job>>> searchJobs(JobSearchFilter filter);

  /// Vagas publicadas por um contratante (aba "Minhas vagas").
  Future<Either<Failure, List<Job>>> getRecruiterJobs(String recruiterId);

  /// Publica uma nova vaga e devolve a vaga gravada.
  Future<Either<Failure, Job>> createJob(JobDraft draft);

  /// Muda a situação da vaga (ex.: encerrar).
  Future<Either<Failure, Unit>> updateJobStatus(String jobId, JobStatus status);
}
