// =============================================================================
// test/modules/reviews/reviews_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 8: avaliações.
//   * resumo (média com 1 casa decimal e quantidade);
//   * validação da nota e do comentário antes de ir ao servidor;
//   * conversão do JSON da função get_reviews.
// Rodar com: flutter test
// =============================================================================

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/reviews/data/repositories/review_repository_impl.dart';
import 'package:audiovisual_app/modules/reviews/domain/entities/review.dart';
import 'package:audiovisual_app/modules/reviews/domain/repositories/review_repository.dart';
import 'package:audiovisual_app/modules/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Right, Unit, unit;

/// Repositório FALSO: guarda o que foi enviado.
class FakeReviewRepository implements ReviewRepository {
  int? sentRating;
  String? sentComment;
  bool called = false;

  @override
  Future<Either<Failure, List<Review>>> getReviewsFor(String userId) async => const Right([]);

  @override
  Future<Either<Failure, bool>> hasReviewed({
    required String applicationId,
    required String reviewerId,
  }) async =>
      const Right(false);

  @override
  Future<Either<Failure, Unit>> submit({
    required String applicationId,
    required int rating,
    String? comment,
  }) async {
    called = true;
    sentRating = rating;
    sentComment = comment;
    return const Right(unit);
  }
}

Review buildReview(int rating) => Review(
      id: 'r$rating',
      rating: rating,
      createdAt: DateTime(2026, 10, 17),
      reviewerName: 'Rita',
      jobTitle: 'Casamento',
    );

void main() {
  group('Resumo das avaliações', () {
    test('lista vazia = média 0', () {
      expect(ReviewSummary.fromReviews(const []), const ReviewSummary(average: 0, count: 0));
    });

    test('média com uma casa decimal', () {
      final summary = ReviewSummary.fromReviews([buildReview(5), buildReview(4), buildReview(5)]);
      expect(summary.average, 4.7); // 14 / 3 = 4,666...
      expect(summary.count, 3);
    });
  });

  group('SubmitReviewUseCase', () {
    late FakeReviewRepository repository;
    late SubmitReviewUseCase useCase;

    setUp(() {
      repository = FakeReviewRepository();
      useCase = SubmitReviewUseCase(repository);
    });

    test('nota fora de 1 a 5 é recusada sem chamar o servidor', () async {
      final result = await useCase(const SubmitReviewParams(applicationId: 'a', rating: 0));
      expect(result.isLeft(), isTrue);
      expect(repository.called, isFalse);
    });

    test('comentário com mais de 500 caracteres é recusado', () async {
      final result = await useCase(
        SubmitReviewParams(applicationId: 'a', rating: 5, comment: 'x' * 501),
      );
      expect(result.isLeft(), isTrue);
    });

    test('comentário só com espaços vira nulo', () async {
      final result = await useCase(
        const SubmitReviewParams(applicationId: 'a', rating: 4, comment: '   '),
      );
      expect(result.isRight(), isTrue);
      expect(repository.sentRating, 4);
      expect(repository.sentComment, isNull);
    });
  });

  test('converte o JSON de get_reviews', () {
    final review = ReviewRepositoryImpl.reviewFromJson({
      'id': 'r1',
      'rating': 5,
      'comment': 'Entregou antes do prazo.',
      'created_at': '2026-10-17T12:00:00Z',
      'reviewer_name': '',
      'reviewer_avatar_url': null,
      'reviewer_was_recruiter': true,
      'job_title': 'Casamento na Barra',
    });
    expect(review.rating, 5);
    expect(review.reviewerName, 'Usuário'); // nome vazio
    expect(review.reviewerWasRecruiter, isTrue);
  });
}
