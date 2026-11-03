// =============================================================================
// modules/applications/domain/usecases/respond_to_offer_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: o PROFISSIONAL responde à proposta de contratação.
//
//   * ACEITAR  -> status "contratado"; o banco cria a conversa e o chat
//                 entre os dois é liberado;
//   * RECUSAR  -> status "proposta recusada".
// Só é possível responder enquanto a proposta estiver "enviada".
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job_application.dart';
import '../repositories/application_repository.dart';

class RespondToOfferParams extends Equatable {
  final JobApplication application;

  /// true = aceitar | false = recusar
  final bool accept;

  const RespondToOfferParams({required this.application, required this.accept});

  @override
  List<Object?> get props => [application, accept];
}

@injectable
class RespondToOfferUseCase
    implements UseCase<ApplicationStatus, RespondToOfferParams> {
  final ApplicationRepository repository;

  RespondToOfferUseCase(this.repository);

  /// Devolve o novo status em caso de sucesso.
  @override
  Future<Either<Failure, ApplicationStatus>> call(RespondToOfferParams params) async {
    final newStatus =
        params.accept ? ApplicationStatus.hired : ApplicationStatus.offerDeclined;

    if (!params.application.status.professionalCanChangeTo(newStatus)) {
      return const Left(
        ValidationFailure('Não há proposta aguardando a sua resposta nesta candidatura.'),
      );
    }

    final result = await repository.updateStatus(params.application.id, newStatus);
    // `map` transforma o valor de sucesso (Unit) no novo status.
    return result.map((_) => newStatus);
  }
}
