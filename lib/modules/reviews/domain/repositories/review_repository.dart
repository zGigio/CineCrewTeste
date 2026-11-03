// =============================================================================
// modules/reviews/domain/repositories/review_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO das avaliações.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/error/failures.dart';
import '../entities/review.dart';

abstract class ReviewRepository {
  /// Avaliações recebidas pelo usuário (mais recentes primeiro).
  Future<Either<Failure, List<Review>>> getReviewsFor(String userId);

  /// O usuário já avaliou esta contratação?
  Future<Either<Failure, bool>> hasReviewed({
    required String applicationId,
    required String reviewerId,
  });

  /// Envia a avaliação (o banco descobre quem é avaliado).
  Future<Either<Failure, Unit>> submit({
    required String applicationId,
    required int rating,
    String? comment,
  });
}
