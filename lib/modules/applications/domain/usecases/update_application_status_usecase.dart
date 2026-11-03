// =============================================================================
// modules/applications/domain/usecases/update_application_status_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: o CONTRATANTE muda o status de uma candidatura
// (aprovar para entrevista, reprovar ou enviar proposta de contratação).
//
// Garante que a mudança respeita o fluxo do processo seletivo
// (ApplicationStatus.recruiterActions). Ex.: não dá para enviar proposta a
// quem não passou pela entrevista, nem mudar quem já foi reprovado.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job_application.dart';
import '../repositories/application_repository.dart';

class UpdateStatusParams extends Equatable {
  final JobApplication application;
  final ApplicationStatus newStatus;

  const UpdateStatusParams({required this.application, required this.newStatus});

  @override
  List<Object?> get props => [application, newStatus];
}

@injectable
class UpdateApplicationStatusUseCase implements UseCase<Unit, UpdateStatusParams> {
  final ApplicationRepository repository;

  UpdateApplicationStatusUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateStatusParams params) async {
    final current = params.application.status;
    if (!current.recruiterCanChangeTo(params.newStatus)) {
      return Left(
        ValidationFailure(
          'Não é possível passar de "${current.label}" para "${params.newStatus.label}".',
        ),
      );
    }
    return repository.updateStatus(params.application.id, params.newStatus);
  }
}
