// =============================================================================
// modules/talent_search/data/models/professional_model.dart
// -----------------------------------------------------------------------------
// MODEL (camada de DADOS).
//
// Diferença entre Entity e Model:
//   - Entity (domínio): o objeto de negócio "puro".
//   - Model (dados): ESTENDE a entidade e acrescenta a capacidade de
//     converter de/para JSON, que é o formato usado pela API.
// Assim, a camada de domínio nunca precisa saber que JSON existe.
// =============================================================================

import '../../domain/entities/location_entity.dart';
import '../../domain/entities/professional_entity.dart';

/// Versão "serializável" de [ProfessionalEntity].
class ProfessionalModel extends ProfessionalEntity {
  /// `super.campo` repassa cada valor diretamente ao construtor da entidade.
  const ProfessionalModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.primaryRole,
    required super.secondarySkills,
    required super.location,
    super.distanceInKm,
    super.bio,
    super.avatarUrl,
    super.rating = 0.0,
    super.isAvailable = true,
  });

  /// Converte o JSON recebido da API (um Map chave -> valor) em um
  /// [ProfessionalModel].
  ///
  /// Os nomes das chaves seguem o padrão "snake_case" do back-end
  /// (ex.: `primary_role`), enquanto no Dart usamos "camelCase"
  /// (ex.: `primaryRole`).
  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      // `.toString()` aceita tanto id numérico (1) quanto texto ("uuid").
      id: json['id'].toString(),
      // `?? ''`: se o campo vier nulo do banco, usa texto vazio.
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      primaryRole: (json['primary_role'] as String?) ?? '',
      // Converte a lista genérica do JSON em List<String>.
      // Se a chave não vier (null), usa lista vazia `[]`.
      secondarySkills: (json['secondary_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      // Monta a entidade de localização a partir dos campos do JSON.
      // `num` aceita int ou double; `.toDouble()` padroniza para double.
      location: LocationEntity(
        // Perfis que ainda não informaram localização vêm com valor nulo;
        // nesse caso usamos 0 (na busca por raio isso nunca acontece, pois
        // o SQL só devolve perfis COM localização).
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
      ),
      // Distância calculada pelo PostGIS (extensão espacial do PostgreSQL)
      // na consulta de busca por raio. Pode não vir (ex.: busca por id).
      distanceInKm: (json['distance_in_km'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      // `??` = "se for nulo, use este valor padrão".
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  /// Converte o objeto de volta para JSON, usado em requisições
  /// POST/PUT (cadastrar ou atualizar um profissional).
  /// A distância não é enviada, pois é sempre calculada pelo servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'primary_role': primaryRole,
      'secondary_skills': secondarySkills,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': location.address,
      'city': location.city,
      'state': location.state,
      'bio': bio,
      'avatar_url': avatarUrl,
      'rating': rating,
      'is_available': isAvailable,
    };
  }
}
