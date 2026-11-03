// =============================================================================
// modules/reviews/domain/usecases/submit_review_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: enviar uma avaliação.
// Confere a nota (1 a 5) e o tamanho do comentário antes de ir ao servidor.
// As outras regras (só depois do pagamento liberado, uma vez por lado...)
// ficam na função `submit_review` do banco.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/review_repository.dart';

class SubmitReviewParams extends Equatable {
  final String applicationId;
  final int rating;
  final String comment;

  const SubmitReviewParams({
    required this.applicationId,
    required this.rating,
    this.comment = '',
  });

  @override
  List<Object?> get props => [applicationId, rating, comment];
}

@injectable
class SubmitReviewUseCase implements UseCase<Unit, SubmitReviewParams> {
  final ReviewRepository repository;

  SubmitReviewUseCase(this.repository);

  static const int maxCommentLength = 500;

  @override
  Future<Either<Failure, Unit>> call(SubmitReviewParams params) async {
    if (params.rating < 1 || params.rating > 5) {
      return const Left(ValidationFailure('Escolha de 1 a 5 estrelas.'));
    }
    final comment = params.comment.trim();
    if (comment.length > maxCommentLength) {
      return const Left(
        ValidationFailure('O comentário pode ter no máximo 500 caracteres.'),
      );
    }
    return repository.submit(
      applicationId: params.applicationId,
      rating: params.rating,
      comment: comment.isEmpty ? null : comment,
    );
  }
}
