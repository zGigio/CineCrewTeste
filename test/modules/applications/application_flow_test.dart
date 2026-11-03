// =============================================================================
// test/modules/applications/application_flow_test.dart
// -----------------------------------------------------------------------------
// TESTES do PROCESSO SELETIVO (regras de negócio das candidaturas).
//
// Verifica a "máquina de estados" do status e os casos de uso:
//   - quem pode fazer cada mudança (contratante x profissional);
//   - que não dá para pular etapas;
//   - as regras para se candidatar.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/applications/domain/entities/job_application.dart';
import 'package:audiovisual_app/modules/applications/domain/repositories/application_repository.dart';
import 'package:audiovisual_app/modules/applications/domain/usecases/apply_to_job_usecase.dart';
import 'package:audiovisual_app/modules/applications/domain/usecases/respond_to_offer_usecase.dart';
import 'package:audiovisual_app/modules/applications/domain/usecases/update_application_status_usecase.dart';
import 'package:audiovisual_app/modules/jobs/domain/entities/job.dart';
import 'package:audiovisual_app/modules/profile/domain/entities/user_profile.dart';

/// Repositório falso: sempre dá certo e conta as chamadas.
class FakeApplicationRepository implements ApplicationRepository {
  int calls = 0;

  @override
  Future<Either<Failure, JobApplication>> apply({
    required String jobId,
    required String professionalId,
    String? coverMessage,
  }) async {
    calls++;
    return Right(
      JobApplication(
        id: 'app-1',
        jobId: jobId,
        professionalId: professionalId,
        coverMessage: coverMessage,
        status: ApplicationStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    calls++;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> cancel(String applicationId) async => const Right(unit);

  @override
  Future<Either<Failure, JobApplication?>> findApplication({
    required String jobId,
    required String professionalId,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<JobApplication>>> getApplicationsForJob(String jobId) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<JobApplication>>> getMyApplications(
    String professionalId,
  ) async =>
      const Right([]);
}

void main() {
  // ---------------------------------------------------------------------------
  // Dados de exemplo
  // ---------------------------------------------------------------------------
  final job = Job(
    id: 'job-1',
    recruiterId: 'carla',
    title: 'Videomaker para casamento',
    description: '',
    requiredRole: 'Videomaker',
    fee: 1500,
    startsAt: DateTime(2030, 1, 10, 8),
    endsAt: DateTime(2030, 1, 10, 18),
    latitude: -22.9,
    longitude: -43.17,
  );

  const ana = UserProfile(id: 'ana', fullName: 'Ana', primaryRole: 'Videomaker');

  JobApplication applicationWith(ApplicationStatus status) => JobApplication(
        id: 'app-1',
        jobId: job.id,
        professionalId: ana.id,
        status: status,
        createdAt: DateTime(2030, 1, 1),
      );

  late FakeApplicationRepository repository;
  setUp(() => repository = FakeApplicationRepository());

  // ---------------------------------------------------------------------------
  group('Máquina de estados do status', () {
    test('contratante: em análise -> entrevista ou reprovado', () {
      expect(ApplicationStatus.pending.recruiterActions,
          [ApplicationStatus.interview, ApplicationStatus.rejected]);
    });

    test('contratante: entrevista -> proposta ou reprovado', () {
      expect(ApplicationStatus.interview.recruiterActions,
          [ApplicationStatus.offerSent, ApplicationStatus.rejected]);
    });

    test('só o profissional responde à proposta', () {
      expect(ApplicationStatus.offerSent.recruiterActions, isEmpty);
      expect(ApplicationStatus.offerSent.professionalActions,
          [ApplicationStatus.hired, ApplicationStatus.offerDeclined]);
    });

    test('estados finais não mudam mais', () {
      expect(ApplicationStatus.rejected.isFinal, isTrue);
      expect(ApplicationStatus.hired.isFinal, isTrue);
      expect(ApplicationStatus.offerDeclined.isFinal, isTrue);
    });

    test('o chat só é liberado depois de contratado', () {
      expect(ApplicationStatus.offerSent.chatUnlocked, isFalse);
      expect(ApplicationStatus.hired.chatUnlocked, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('UpdateApplicationStatusUseCase (contratante)', () {
    test('não deixa pular a entrevista e contratar direto', () async {
      final result = await UpdateApplicationStatusUseCase(repository)(
        UpdateStatusParams(
          application: applicationWith(ApplicationStatus.pending),
          newStatus: ApplicationStatus.offerSent,
        ),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });

    test('aprova para entrevista', () async {
      final result = await UpdateApplicationStatusUseCase(repository)(
        UpdateStatusParams(
          application: applicationWith(ApplicationStatus.pending),
          newStatus: ApplicationStatus.interview,
        ),
      );
      expect(result.isRight(), isTrue);
      expect(repository.calls, 1);
    });
  });

  // ---------------------------------------------------------------------------
  group('RespondToOfferUseCase (profissional)', () {
    test('aceitar a proposta resulta em "contratado"', () async {
      final result = await RespondToOfferUseCase(repository)(
        RespondToOfferParams(
          application: applicationWith(ApplicationStatus.offerSent),
          accept: true,
        ),
      );
      expect(result, const Right<Failure, ApplicationStatus>(ApplicationStatus.hired));
    });

    test('não dá para aceitar sem ter recebido proposta', () async {
      final result = await RespondToOfferUseCase(repository)(
        RespondToOfferParams(
          application: applicationWith(ApplicationStatus.interview),
          accept: true,
        ),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });
  });

  // ---------------------------------------------------------------------------
  group('ApplyToJobUseCase', () {
    test('profissional com perfil completo se candidata', () async {
      final result = await ApplyToJobUseCase(repository)(
        ApplyParams(job: job, applicant: ana, coverMessage: 'Tenho drone 4K'),
      );
      expect(result.isRight(), isTrue);
    });

    test('não pode se candidatar à própria vaga', () async {
      const carla = UserProfile(
        id: 'carla',
        fullName: 'Carla',
        isRecruiter: true,
        primaryRole: 'Produtora',
      );
      final result = await ApplyToJobUseCase(repository)(
        ApplyParams(job: job, applicant: carla),
      );
      expect(result.isLeft(), isTrue);
    });

    test('exige a função principal no perfil', () async {
      const semFuncao = UserProfile(id: 'bruno', fullName: 'Bruno');
      final result = await ApplyToJobUseCase(repository)(
        ApplyParams(job: job, applicant: semFuncao),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });
  });
}
