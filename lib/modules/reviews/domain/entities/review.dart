// =============================================================================
// modules/reviews/domain/entities/review.dart
// -----------------------------------------------------------------------------
// ENTIDADE: AVALIAÇÃO recebida por um usuário (estrelas + comentário).
// Também traz o RESUMO (média e quantidade), calculado a partir da lista.
// =============================================================================

import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;

  /// Nota de 1 a 5 estrelas.
  final int rating;

  /// Comentário opcional.
  final String? comment;
  final DateTime createdAt;

  /// Quem avaliou.
  final String reviewerName;
  final String? reviewerAvatarUrl;

  /// Quem avaliou era o contratante da vaga? (senão, era o profissional)
  final bool reviewerWasRecruiter;

  /// Título da vaga em que trabalharam juntos.
  final String jobTitle;

  const Review({
    required this.id,
    required this.rating,
    required this.createdAt,
    required this.reviewerName,
    required this.jobTitle,
    this.comment,
    this.reviewerAvatarUrl,
    this.reviewerWasRecruiter = false,
  });

  @override
  List<Object?> get props => [
        id, rating, comment, createdAt, reviewerName,
        reviewerAvatarUrl, reviewerWasRecruiter, jobTitle,
      ];
}

/// Resumo das avaliações: média (1 casa decimal) e quantidade.
class ReviewSummary extends Equatable {
  final double average;
  final int count;

  const ReviewSummary({required this.average, required this.count});

  /// Calcula o resumo a partir da lista (lista vazia -> média 0).
  factory ReviewSummary.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) return const ReviewSummary(average: 0, count: 0);
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    final average = (total / reviews.length * 10).round() / 10;
    return ReviewSummary(average: average, count: reviews.length);
  }

  @override
  List<Object?> get props => [average, count];
}
