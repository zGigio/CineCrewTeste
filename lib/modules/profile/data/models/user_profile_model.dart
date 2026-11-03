// =============================================================================
// modules/profile/data/models/user_profile_model.dart
// -----------------------------------------------------------------------------
// MODEL do perfil (camada de DADOS).
//
// Estende a entidade [UserProfile] e acrescenta a conversão de/para o JSON
// da tabela `profiles` do Supabase. Os nomes das colunas no banco usam
// "snake_case" (full_name), e no Dart usamos "camelCase" (fullName).
// =============================================================================

import '../../domain/entities/user_profile.dart';

/// Perfil com conversão para JSON.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    super.isProfessional,
    super.isRecruiter,
    super.primaryRole,
    super.secondarySkills,
    super.bio,
    super.avatarUrl,
    super.resumePath,
    super.companyName,
    super.city,
    super.state,
    super.latitude,
    super.longitude,
    super.rating,
    super.reviewsCount,
    super.headline,
    super.coverUrl,
    super.approxLatitude,
    super.approxLongitude,
    super.locationConsentAt,
    super.deactivatedAt,
    super.lastMode,
    super.isAvailable,
  });

  /// Converte uma linha da tabela `profiles` (JSON) em [UserProfileModel].
  /// Campos que podem vir nulos recebem um valor padrão com `??`.
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isProfessional: (json['is_professional'] as bool?) ?? true,
      isRecruiter: (json['is_recruiter'] as bool?) ?? false,
      primaryRole: json['primary_role'] as String?,
      secondarySkills: (json['secondary_skills'] as List<dynamic>?)
              ?.map((skill) => skill.toString())
              .toList() ??
          const [],
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      resumePath: json['resume_path'] as String?,
      companyName: json['company_name'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      // `num` aceita inteiro ou decimal; `.toDouble()` padroniza.
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      headline: json['headline'] as String?,
      coverUrl: json['cover_url'] as String?,
      approxLatitude: (json['approx_latitude'] as num?)?.toDouble(),
      approxLongitude: (json['approx_longitude'] as num?)?.toDouble(),
      deactivatedAt: json['deactivated_at'] == null
          ? null
          : DateTime.parse(json['deactivated_at'] as String).toLocal(),
      lastMode: json['last_mode'] as String?,
      isAvailable: (json['is_available'] as bool?) ?? true,
    );
  }

  /// Monta o JSON com os campos que o PRÓPRIO usuário pode alterar.
  ///
  /// Ficam de fora: id, e-mail (vem do login), avaliação (calculada) e as
  /// URLs de foto/capa/currículo (atualizadas no envio do arquivo).
  /// Textos vazios viram `null` no banco, para não guardar "" sem sentido.
  static Map<String, dynamic> toUpdateJson(UserProfile profile) {
    return {
      'full_name': profile.fullName.trim(),
      'phone': _emptyToNull(profile.phone),
      'is_professional': profile.isProfessional,
      'is_recruiter': profile.isRecruiter,
      'primary_role': _emptyToNull(profile.primaryRole),
      'secondary_skills': profile.secondarySkills,
      'bio': _emptyToNull(profile.bio),
      'headline': _emptyToNull(profile.headline),
      'company_name': _emptyToNull(profile.companyName),
      'city': _emptyToNull(profile.city),
      'state': _emptyToNull(profile.state),
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'is_available': profile.isAvailable,
    };
  }

  /// Converte texto vazio (ou só espaços) em `null`.
  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
