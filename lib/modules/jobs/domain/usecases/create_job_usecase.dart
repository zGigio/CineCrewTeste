// =============================================================================
// modules/jobs/domain/usecases/create_job_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: PUBLICAR UMA VAGA.
//
// Regras de negócio verificadas antes de gravar:
//   1. título com pelo menos 5 caracteres;
//   2. função procurada informada;
//   3. cachê não pode ser negativo;
//   4. o trabalho precisa começar no futuro;
//   5. o fim precisa ser depois do início;
//   6. coordenadas válidas (local marcado no mapa).
// O banco de dados também confere algumas dessas regras (dupla proteção).
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../entities/job_draft.dart';
import '../repositories/job_repository.dart';

@injectable
class CreateJobUseCase implements UseCase<Job, JobDraft> {
  static const int minTitleLength = 5;

  final JobRepository repository;

  CreateJobUseCase(this.repository);

  @override
  Future<Either<Failure, Job>> call(JobDraft draft) async {
    if (draft.title.trim().length < minTitleLength) {
      return const Left(
        ValidationFailure('O título deve ter pelo menos $minTitleLength caracteres.'),
      );
    }
    if (draft.requiredRole.trim().isEmpty) {
      return const Left(ValidationFailure('Escolha a função procurada.'));
    }
    if (draft.fee < 0) {
      return const Left(ValidationFailure('O cachê não pode ser negativo.'));
    }
    if (draft.startsAt.isBefore(DateTime.now())) {
      return const Left(ValidationFailure('O trabalho precisa começar no futuro.'));
    }
    if (!draft.endsAt.isAfter(draft.startsAt)) {
      return const Left(
        ValidationFailure('O fim do trabalho deve ser depois do início.'),
      );
    }
    if (draft.latitude < -90 || draft.latitude > 90 ||
        draft.longitude < -180 || draft.longitude > 180) {
      return const Left(ValidationFailure('Marque o local da vaga no mapa.'));
    }

    return repository.createJob(draft);
  }
}
