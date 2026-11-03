// =============================================================================
// modules/profile/data/profile_columns.dart
// -----------------------------------------------------------------------------
// COLUNAS DO PERFIL que o app pode ler de QUALQUER usuário.
//
// Desde a Parte 11, o banco não deixa ler `latitude`, `longitude` nem
// `location` (a coordenada EXATA) de outras pessoas — só a posição
// APROXIMADA (`approx_latitude`/`approx_longitude`, grade de ~1,1 km).
// Por isso as consultas não podem usar `select *`: listam as colunas aqui.
// =============================================================================

class ProfileColumns {
  ProfileColumns._();

  /// Lista no formato do PostgREST (separada por vírgulas).
  static const String public =
      'id, email, full_name, phone, is_professional, is_recruiter, '
      'primary_role, secondary_skills, bio, avatar_url, resume_path, company_name, '
      'city, state, rating, reviews_count, is_available, headline, cover_url, '
      'approx_latitude, approx_longitude, deactivated_at, last_mode';
}
