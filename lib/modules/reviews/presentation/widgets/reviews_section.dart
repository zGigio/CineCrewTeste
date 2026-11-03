// =============================================================================
// modules/reviews/presentation/widgets/reviews_section.dart
// -----------------------------------------------------------------------------
// SEÇÃO "AVALIAÇÕES" do perfil público (como as recomendações do LinkedIn):
//
//   4,7 ★★★★⯪   (12 avaliações)
//   ┌───────────────────────────────────┐
//   │ (foto) Rita · Contratante  ★★★★★  │
//   │ Casamento na Barra · 17/10/2026   │
//   │ "Entregou antes do prazo."        │
//   └───────────────────────────────────┘
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import 'rating_stars.dart';

class ReviewsSection extends StatefulWidget {
  /// Usuário cujas avaliações RECEBIDAS serão mostradas.
  final String userId;

  const ReviewsSection({super.key, required this.userId});

  /// Quantas avaliações aparecem antes do botão "Ver todas".
  static const int previewCount = 3;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  List<Review>? _reviews; // null = carregando
  String? _error;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<ReviewRepository>().getReviewsFor(widget.userId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (reviews) => setState(() => _reviews = reviews),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = _reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avaliações', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error))
        else if (reviews == null)
          const Center(child: CircularProgressIndicator())
        else if (reviews.isEmpty)
          Text(
            'Ainda sem avaliações. Elas aparecem depois dos primeiros trabalhos.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          _SummaryRow(summary: ReviewSummary.fromReviews(reviews)),
          const SizedBox(height: 8),
          for (final review in _showAll
              ? reviews
              : reviews.take(ReviewsSection.previewCount))
            _ReviewCard(review: review),
          if (!_showAll && reviews.length > ReviewsSection.previewCount)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text('Ver todas as ${reviews.length} avaliações'),
            ),
        ],
      ],
    );
  }
}

/// "4,7 ★★★★⯪ (12 avaliações)"
class _SummaryRow extends StatelessWidget {
  final ReviewSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          summary.average.toStringAsFixed(1).replaceAll('.', ','),
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        RatingStars(rating: summary.average, size: 22),
        const SizedBox(width: 8),
        Text(
          summary.count == 1 ? '(1 avaliação)' : '(${summary.count} avaliações)',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = review.reviewerWasRecruiter ? 'Contratante' : 'Profissional';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  imageUrl: review.reviewerAvatarUrl,
                  name: review.reviewerName,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(role, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating.toDouble(), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${review.jobTitle} · ${Formatters.date(review.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (review.comment != null) ...[
              const SizedBox(height: 6),
              Text('"${review.comment!}"', style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
