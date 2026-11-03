// =============================================================================
// modules/applications/domain/repositories/application_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do repositório de CANDIDATURAS (camada de DOMÍNIO).
// =============================================================================

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/job_application.dart';

abstract class ApplicationRepository {
  /// Cria a candidatura do profissional na vaga (status inicial: pendente).
  Future<Either<Failure, JobApplication>> apply({
    required String jobId,
    required String professionalId,
    String? coverMessage,
  });

  /// Candidaturas do profissional, com os dados de cada vaga.
  Future<Either<Failure, List<JobApplication>>> getMyApplications(
    String professionalId,
  );

  /// Candidatos de uma vaga, com o perfil de cada um (visão do contratante).
  Future<Either<Failure, List<JobApplication>>> getApplicationsForJob(String jobId);

  /// Procura a candidatura do profissional naquela vaga.
  /// Devolve `null` (dentro do Right) se ele ainda não se candidatou.
  Future<Either<Failure, JobApplication?>> findApplication({
    required String jobId,
    required String professionalId,
  });

  /// Muda o status (aprovar para entrevista, reprovar, contratar).
  Future<Either<Failure, Unit>> updateStatus(
    String applicationId,
    ApplicationStatus status,
  );

  /// Cancela (apaga) a candidatura ainda pendente.
  Future<Either<Failure, Unit>> cancel(String applicationId);
}
