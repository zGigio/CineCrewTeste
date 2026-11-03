// =============================================================================
// core/services/geocoding/geo_place.dart
// -----------------------------------------------------------------------------
// LUGAR ENCONTRADO (resultado da geocodificação): coordenada + rótulo
// legível + cidade e UF. É o que a tela "Definir localização" (TEL08)
// devolve, tanto para a base do profissional quanto para o local do set.
// =============================================================================

import 'package:equatable/equatable.dart';

class GeoPlace extends Equatable {
  final double latitude;
  final double longitude;

  /// Texto curto para mostrar na tela (ex.: "Centro, Rio de Janeiro · RJ").
  final String label;
  final String? city;

  /// Sigla do estado (UF), ex.: "RJ".
  final String? state;

  const GeoPlace({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.city,
    this.state,
  });

  /// Coordenada válida? Latitude em [-90, 90], longitude em [-180, 180]
  /// e nunca (0, 0) — o ponto "no meio do oceano" que aparece quando um
  /// sistema não encontra nada (regra da TEL08).
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  @override
  List<Object?> get props => [latitude, longitude, label, city, state];
}
