// =============================================================================
// modules/talent_search/domain/entities/location_entity.dart
// -----------------------------------------------------------------------------
// ENTIDADE de LOCALIZAÇÃO (camada de DOMÍNIO).
//
// Entidades são os objetos centrais do negócio. Elas NÃO dependem de API,
// banco de dados ou Flutter — são Dart puro. Isso as torna estáveis e fáceis
// de testar.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Representa um ponto no mapa: a base de um profissional ou um local de
/// gravação (set de filmagem).
class LocationEntity extends Equatable {
  /// Latitude em graus decimais (de -90 a 90). Ex.: -22.9068 (Rio de Janeiro).
  final double latitude;

  /// Longitude em graus decimais (de -180 a 180). Ex.: -43.1729.
  final double longitude;

  /// Endereço por extenso (opcional — o `?` indica que pode ser nulo).
  final String? address;

  /// Cidade (opcional).
  final String? city;

  /// Estado / UF (opcional). Ex.: "RJ".
  final String? state;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
  });

  /// Campos usados para comparar duas localizações por valor.
  @override
  List<Object?> get props => [latitude, longitude, address, city, state];
}
