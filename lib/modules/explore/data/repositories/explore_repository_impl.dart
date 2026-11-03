// =============================================================================
// modules/explore/data/repositories/explore_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do modo Contratar usando o SUPABASE:
//   * busca -> função `search_talents` (PostGIS, posição aproximada);
//   * projetos -> tabela `projects` (só o dono vê, pela regra de RLS).
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/search_criteria.dart';
import '../../domain/entities/talent_result.dart';
import '../../domain/repositories/explore_repository.dart';

@LazySingleton(as: ExploreRepository)
class ExploreRepositoryImpl implements ExploreRepository {
  final SupabaseClient _client;

  ExploreRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<TalentResult>>> searchTalents(SearchCriteria criteria) {
    return guardRequest<List<TalentResult>>(() async {
      final place = criteria.place!;
      final rows = await _client.rpc('search_talents', params: {
        'p_lat': place.latitude,
        'p_lng': place.longitude,
        'p_radius_km': criteria.radiusKm,
        'p_specialties': criteria.specialties,
        'p_only_available': criteria.onlyAvailable,
      }) as List<dynamic>;
      return rows.map((row) => talentFromJson(row as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<Either<Failure, List<Project>>> getProjects() {
    return guardRequest<List<Project>>(() async {
      final rows = await _client
          .from('projects')
          .select()
          .order('updated_at', ascending: false);
      return rows.map(projectFromJson).toList();
    });
  }

  @override
  Future<Either<Failure, Project>> saveProject(Project project) {
    return guardRequest<Project>(() async {
      final data = {
        'owner_id': _client.auth.currentUser!.id,
        'name': project.name,
        'latitude': project.place.latitude,
        'longitude': project.place.longitude,
        'location_label': project.place.label,
        'city': project.place.city,
        'state': project.place.state,
        'radius_km': project.radiusKm,
        'specialties': project.specialties,
      };
      final query = project.id == null
          ? _client.from('projects').insert(data)
          : _client.from('projects').update(data).eq('id', project.id!);
      return projectFromJson(await query.select().single());
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteProject(String projectId) {
    return guardRequest<Unit>(() async {
      await _client.from('projects').delete().eq('id', projectId);
      return unit;
    });
  }

  // ---- Conversões JSON -> entidades (públicas para os testes) ---------------

  static TalentResult talentFromJson(Map<String, dynamic> json) {
    return TalentResult(
      id: json['id'] as String,
      name: ((json['name'] as String?) ?? '').trim().isEmpty
          ? 'Profissional'
          : (json['name'] as String).trim(),
      headline: json['headline'] as String?,
      primaryRole: json['primary_role'] as String?,
      secondarySkills: (json['secondary_skills'] as List<dynamic>? ?? const [])
          .map((skill) => skill.toString())
          .toList(),
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isAvailable: (json['is_available'] as bool?) ?? true,
      approxLatitude: (json['latitude'] as num).toDouble(),
      approxLongitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_in_km'] as num).toDouble(),
    );
  }

  static Project projectFromJson(Map<String, dynamic> json) {
    final updated = json['updated_at'] as String?;
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      place: GeoPlace(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        label: (json['location_label'] as String?) ?? '',
        city: json['city'] as String?,
        state: json['state'] as String?,
      ),
      radiusKm: (json['radius_km'] as num).toInt(),
      specialties: (json['specialties'] as List<dynamic>).map((s) => s.toString()).toList(),
      updatedAt: updated == null ? null : DateTime.parse(updated).toLocal(),
    );
  }
}
