// =============================================================================
// test/modules/jobs/job_usecases_test.dart
// -----------------------------------------------------------------------------
// TESTES das REGRAS DE NEGÓCIO das vagas (casos de uso).
//
// Usamos um repositório FALSO que só conta quantas vezes foi chamado.
// Assim verificamos que, quando a regra é violada, o caso de uso devolve
// uma ValidationFailure e NEM CHEGA a chamar o banco de dados.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/jobs/domain/entities/job.dart';
import 'package:audiovisual_app/modules/jobs/domain/entities/job_draft.dart';
import 'package:audiovisual_app/modules/jobs/domain/entities/job_search_filter.dart';
import 'package:audiovisual_app/modules/jobs/domain/repositories/job_repository.dart';
import 'package:audiovisual_app/modules/jobs/domain/usecases/create_job_usecase.dart';
import 'package:audiovisual_app/modules/jobs/domain/usecases/search_jobs_usecase.dart';

/// Repositório falso: devolve sucesso e conta as chamadas.
class FakeJobRepository implements JobRepository {
  int calls = 0;

  Job _fakeJob(JobDraft draft) => Job(
        id: 'job-1',
        recruiterId: draft.recruiterId,
        title: draft.title,
        description: draft.description,
        requiredRole: draft.requiredRole,
        fee: draft.fee,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        latitude: draft.latitude,
        longitude: draft.longitude,
      );

  @override
  Future<Either<Failure, Job>> createJob(JobDraft draft) async {
    calls++;
    return Right(_fakeJob(draft));
  }

  @override
  Future<Either<Failure, List<Job>>> searchJobs(JobSearchFilter filter) async {
    calls++;
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Job>>> getRecruiterJobs(String recruiterId) async =>
      const Right([]);

  @override
  Future<Either<Failure, Unit>> updateJobStatus(String jobId, JobStatus status) async =>
      const Right(unit);
}

void main() {
  late FakeJobRepository repository;

  setUp(() => repository = FakeJobRepository());

  // Rascunho válido usado como base; cada teste altera um campo.
  JobDraft validDraft({
    String title = 'Videomaker para casamento',
    String role = 'Videomaker',
    double fee = 1500,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    final start = startsAt ?? DateTime.now().add(const Duration(days: 3));
    return JobDraft(
      recruiterId: 'recrutador-1',
      title: title,
      description: '',
      requiredRole: role,
      fee: fee,
      startsAt: start,
      endsAt: endsAt ?? start.add(const Duration(hours: 8)),
      latitude: -22.9068,
      longitude: -43.1729,
    );
  }

  group('CreateJobUseCase', () {
    test('publica uma vaga válida', () async {
      final result = await CreateJobUseCase(repository)(validDraft());
      expect(result.isRight(), isTrue);
      expect(repository.calls, 1);
    });

    test('recusa título curto', () async {
      final result = await CreateJobUseCase(repository)(validDraft(title: 'Vid'));
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });

    test('recusa cachê negativo', () async {
      final result = await CreateJobUseCase(repository)(validDraft(fee: -10));
      expect(result.isLeft(), isTrue);
    });

    test('recusa trabalho no passado', () async {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final result = await CreateJobUseCase(repository)(validDraft(startsAt: past));
      expect(result.isLeft(), isTrue);
    });

    test('recusa fim antes do início', () async {
      final start = DateTime.now().add(const Duration(days: 2));
      final result = await CreateJobUseCase(repository)(
        validDraft(startsAt: start, endsAt: start.subtract(const Duration(hours: 1))),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });
  });

  group('SearchJobsUseCase', () {
    test('busca com filtro válido', () async {
      final result = await SearchJobsUseCase(repository)(
        const JobSearchFilter(latitude: -22.9, longitude: -43.2, radiusKm: 25),
      );
      expect(result.isRight(), isTrue);
      expect(repository.calls, 1);
    });

    test('recusa raio fora dos limites', () async {
      final result = await SearchJobsUseCase(repository)(
        const JobSearchFilter(latitude: -22.9, longitude: -43.2, radiusKm: 900),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });

    test('recusa data final antes da inicial', () async {
      final result = await SearchJobsUseCase(repository)(
        JobSearchFilter(
          latitude: -22.9,
          longitude: -43.2,
          radiusKm: 25,
          dateFrom: DateTime(2026, 12, 10),
          dateTo: DateTime(2026, 12, 1),
        ),
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
