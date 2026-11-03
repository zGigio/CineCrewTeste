// =============================================================================
// modules/reviews/data/repositories/review_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO das avaliações usando o SUPABASE:
//   * lista   -> função SQL `get_reviews` (já traz nome, foto e vaga);
//   * enviar  -> função SQL `submit_review` (confere as regras e recalcula
//                a média no perfil);
//   * já avaliei? -> consulta simples na tabela `reviews`.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

@LazySingleton(as: ReviewRepository)
class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;

  ReviewRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Review>>> getReviewsFor(String userId) {
    return guardRequest<List<Review>>(() async {
      final response = await _client.rpc('get_reviews', params: {'p_user_id': userId});
      return (response as List<dynamic>)
          .map((row) => reviewFromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Either<Failure, bool>> hasReviewed({
    required String applicationId,
    required String reviewerId,
  }) {
    return guardRequest<bool>(() async {
      final row = await _client
          .from('reviews')
          .select('id')
          .eq('application_id', applicationId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();
      return row != null;
    });
  }

  @override
  Future<Either<Failure, Unit>> submit({
    required String applicationId,
    required int rating,
    String? comment,
  }) {
    return guardRequest<Unit>(() async {
      await _client.rpc('submit_review', params: {
        'p_application_id': applicationId,
        'p_rating': rating,
        'p_comment': comment,
      });
      return unit;
    });
  }

  /// JSON (linha da função get_reviews) -> entidade. Público para os testes.
  static Review reviewFromJson(Map<String, dynamic> json) {
    final name = (json['reviewer_name'] as String?)?.trim();
    return Review(
      id: json['id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      // Perfil sem nome: mostra "Usuário".
      reviewerName: name == null || name.isEmpty ? 'Usuário' : name,
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
      reviewerWasRecruiter: (json['reviewer_was_recruiter'] as bool?) ?? false,
      jobTitle: (json['job_title'] as String?) ?? '',
    );
  }
}
