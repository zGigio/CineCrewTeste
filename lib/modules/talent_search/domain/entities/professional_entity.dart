// =============================================================================
// modules/talent_search/domain/entities/professional_entity.dart
// -----------------------------------------------------------------------------
// ENTIDADE PRINCIPAL do Banco de Talentos (camada de DOMÍNIO).
//
// Representa um profissional técnico da indústria audiovisual cadastrado no
// banco de talentos (diretor de fotografia, técnico de som, gaffer, etc.).
// =============================================================================

import 'package:equatable/equatable.dart';
import 'location_entity.dart';

/// Profissional técnico do audiovisual.
class ProfessionalEntity extends Equatable {
  /// Identificador único do profissional no banco de dados.
  final String id;

  /// Nome completo.
  final String name;

  /// E-mail de contato.
  final String email;

  /// Telefone de contato (opcional).
  final String? phone;

  /// Função principal. Ex.: "Diretor de Fotografia", "Técnico de Som Direto".
  final String primaryRole;

  /// Habilidades secundárias. Ex.: ["Operador de Steadicam", "Colorista"].
  final List<String> secondarySkills;

  /// Localização base do profissional (onde ele mora/atua).
  final LocationEntity location;

  /// Distância (em km) entre o profissional e o ponto da busca.
  /// Não fica salva no banco: é CALCULADA pelo servidor (PostGIS) a cada
  /// busca espacial. Por isso é opcional (nula fora de uma busca).
  final double? distanceInKm;

  /// Mini-currículo / apresentação (opcional).
  final String? bio;

  /// URL pública da foto de perfil (opcional).
  final String? avatarUrl;

  /// Avaliação média do profissional (ex.: 4.8). Padrão: 0.0.
  final double rating;

  /// Indica se o profissional está disponível para novos trabalhos.
  final bool isAvailable;

  const ProfessionalEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.primaryRole,
    required this.secondarySkills,
    required this.location,
    this.distanceInKm,
    this.bio,
    this.avatarUrl,
    this.rating = 0.0,
    this.isAvailable = true,
  });

  /// Campos usados pelo Equatable para comparar dois profissionais.
  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        primaryRole,
        secondarySkills,
        location,
        distanceInKm,
        bio,
        avatarUrl,
        rating,
        isAvailable,
      ];
}
