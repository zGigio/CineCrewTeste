// =============================================================================
// modules/portfolio/data/repositories/portfolio_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do portfólio e das experiências usando o SUPABASE.
//
//   * Fotos: arquivo na pasta pública "portfolio" ("<id>/itens/<data>.jpg")
//     + linha na tabela `portfolio_items`;
//   * Vídeos: só a linha, com o link;
//   * Experiências: tabela `experiences`.
// As regras de segurança (só o dono altera) ficam no banco (RLS).
// =============================================================================

import 'dart:typed_data';

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions, SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/portfolio_item.dart';
import '../../domain/repositories/portfolio_repository.dart';

@LazySingleton(as: PortfolioRepository)
class PortfolioRepositoryImpl implements PortfolioRepository {
  static const String _bucket = 'portfolio';

  final SupabaseClient _client;

  PortfolioRepositoryImpl(this._client);

  // ---------------------------------------------------------------------------
  // PORTFÓLIO
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PortfolioItem>>> getItems(String userId) {
    return guardRequest<List<PortfolioItem>>(() async {
      final rows = await _client
          .from('portfolio_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map(_itemFromRow).toList();
    });
  }

  @override
  Future<Either<Failure, PortfolioItem>> addPhoto({
    required String userId,
    required Uint8List bytes,
    required String title,
    String? description,
  }) {
    return guardRequest<PortfolioItem>(() async {
      // Nome único por envio (milissegundos desde 1970).
      final path = '$userId/itens/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      try {
        final row = await _client
            .from('portfolio_items')
            .insert({
              'user_id': userId,
              'media_type': PortfolioMediaType.photo.value,
              'title': title,
              'description': description,
              'image_path': path,
            })
            .select()
            .single();
        return _itemFromRow(row);
      } catch (_) {
        // Se a linha não foi criada (ex.: limite de 30 itens), apaga a foto
        // enviada para não deixar arquivo "órfão" no armazenamento.
        await _client.storage.from(_bucket).remove([path]);
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, PortfolioItem>> addVideo({
    required String userId,
    required String url,
    required String title,
    String? description,
  }) {
    return guardRequest<PortfolioItem>(() async {
      final row = await _client
          .from('portfolio_items')
          .insert({
            'user_id': userId,
            'media_type': PortfolioMediaType.video.value,
            'title': title,
            'description': description,
            'video_url': url,
          })
          .select()
          .single();
      return _itemFromRow(row);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(PortfolioItem item) {
    return guardRequest<Unit>(() async {
      await _client.from('portfolio_items').delete().eq('id', item.id);
      if (item.imagePath != null) {
        await _client.storage.from(_bucket).remove([item.imagePath!]);
      }
      return unit;
    });
  }

  PortfolioItem _itemFromRow(Map<String, dynamic> row) {
    final imagePath = row['image_path'] as String?;
    return PortfolioItem(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: PortfolioMediaType.fromValue(row['media_type'] as String?),
      title: row['title'] as String,
      description: row['description'] as String?,
      imagePath: imagePath,
      // A pasta é pública: a URL é montada a partir do caminho.
      imageUrl: imagePath == null ? null : _client.storage.from(_bucket).getPublicUrl(imagePath),
      videoUrl: row['video_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPERIÊNCIAS
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<Experience>>> getExperiences(String userId) {
    return guardRequest<List<Experience>>(() async {
      final rows = await _client
          .from('experiences')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);
      final experiences = rows.map(experienceFromJson).toList();
      // Trabalhos atuais (sem data de fim) aparecem primeiro.
      experiences.sort((a, b) {
        if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
        return b.startDate.compareTo(a.startDate);
      });
      return experiences;
    });
  }

  @override
  Future<Either<Failure, Experience>> saveExperience(String userId, Experience experience) {
    return guardRequest<Experience>(() async {
      final data = experienceToJson(userId, experience);
      final query = experience.id == null
          ? _client.from('experiences').insert(data)
          : _client.from('experiences').update(data).eq('id', experience.id!);
      final row = await query.select().single();
      return experienceFromJson(row);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteExperience(String experienceId) {
    return guardRequest<Unit>(() async {
      await _client.from('experiences').delete().eq('id', experienceId);
      return unit;
    });
  }

  // ---- Conversões (públicas para os testes) ---------------------------------

  static Experience experienceFromJson(Map<String, dynamic> json) {
    final end = json['end_date'] as String?;
    return Experience(
      id: json['id'] as String,
      role: json['role'] as String,
      production: json['production'] as String,
      category: json['category'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: end == null ? null : DateTime.parse(end),
      description: json['description'] as String?,
    );
  }

  static Map<String, dynamic> experienceToJson(String userId, Experience experience) {
    return {
      'user_id': userId,
      'role': experience.role,
      'production': experience.production,
      'category': experience.category,
      'start_date': _dateOnly(experience.startDate),
      'end_date': experience.endDate == null ? null : _dateOnly(experience.endDate!),
      'description': experience.description,
    };
  }

  /// "2024-03-01" (o tipo `date` do banco não tem hora).
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
