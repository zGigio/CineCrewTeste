// =============================================================================
// core/services/geocoding/geocoding_service.dart
// -----------------------------------------------------------------------------
// GEOCODIFICAÇÃO: transforma ENDEREÇO ou CEP em COORDENADA (e o contrário).
// Decisão para a pendência P04/L01 da documentação (provedor de mapas):
//
//   * CEP (8 números) -> ViaCEP (viacep.com.br): rua, bairro, cidade e UF;
//   * endereço -> coordenada: Nominatim, o geocodificador do OpenStreetMap
//     (o mesmo projeto dos mapas que o app já usa);
//   * coordenada -> cidade/UF (geocodificação reversa): Nominatim.
//
// Os dois serviços são gratuitos e não precisam de chave. O Nominatim pede
// um "User-Agent" que identifique o app e no máximo 1 consulta por segundo
// (a pessoa toca em "Localizar", então o uso fica bem abaixo disso).
//
// Usamos o HttpClient do próprio Dart (dart:io): nenhum pacote extra.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart' show Either, Left, Right;
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import 'geo_place.dart';

abstract class GeocodingService {
  /// Procura um endereço ou CEP. Devolve até 5 lugares (lista vazia = nada
  /// encontrado). Com mais de um, a tela pede para a pessoa escolher.
  Future<Either<Failure, List<GeoPlace>>> search(String query);

  /// Descobre cidade e UF de uma coordenada (ex.: ponto marcado no mapa).
  /// Se não conseguir, devolve o lugar só com a coordenada.
  Future<GeoPlace> reverse(double latitude, double longitude);
}

@LazySingleton(as: GeocodingService)
class GeocodingServiceImpl implements GeocodingService {
  static const String _userAgent = 'CineCrew-TCC/1.0 (app academico UVA)';
  static const Duration _timeout = Duration(seconds: 12);

  @override
  Future<Either<Failure, List<GeoPlace>>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) {
      return const Left(ValidationFailure('Digite o endereço ou o CEP.'));
    }
    try {
      final cep = onlyCep(text);
      final String freeText;
      if (cep != null) {
        // 1) CEP -> endereço (ViaCEP). 2) endereço -> coordenada (Nominatim).
        final address = await _getJson(Uri.https('viacep.com.br', '/ws/$cep/json/'));
        if (address is! Map<String, dynamic> || address['erro'] != null) {
          return const Right([]); // CEP inexistente
        }
        freeText = [
          address['logradouro'],
          address['bairro'],
          address['localidade'],
          address['uf'],
        ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
      } else {
        freeText = text;
      }

      final results = await _getJson(Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': freeText,
        'format': 'jsonv2',
        'addressdetails': '1',
        'countrycodes': 'br', // só Brasil
        'limit': '5',
      }));
      final places = (results as List<dynamic>)
          .map((item) => placeFromNominatim(item as Map<String, dynamic>))
          .where((place) => place.isValid)
          .toList();
      return Right(places);
    } on SocketException {
      return const Left(ServerFailure(
        message: 'Sem conexão para procurar o endereço. Tente de novo ou marque no mapa.',
      ));
    } catch (_) {
      return const Left(ServerFailure(
        message: 'Não foi possível procurar o endereço agora. Marque o ponto no mapa.',
      ));
    }
  }

  @override
  Future<GeoPlace> reverse(double latitude, double longitude) async {
    final fallback = GeoPlace(
      latitude: latitude,
      longitude: longitude,
      label: 'Ponto marcado no mapa',
    );
    try {
      final json = await _getJson(Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$latitude',
        'lon': '$longitude',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '14', // nível de bairro: não precisamos do número da casa
      }));
      if (json is! Map<String, dynamic> || json['error'] != null) return fallback;
      // Mantém a coordenada EXATA marcada; do serviço só usamos os nomes.
      final place = placeFromNominatim(json);
      return GeoPlace(
        latitude: latitude,
        longitude: longitude,
        label: place.label,
        city: place.city,
        state: place.state,
      );
    } catch (_) {
      return fallback;
    }
  }

  /// GET que devolve o JSON já convertido (Map ou List).
  Future<Object?> _getJson(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, _userAgent)
        ..set(HttpHeaders.acceptLanguageHeader, 'pt-BR');
      final response = await request.close().timeout(_timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Funções puras (sem internet) — públicas para os testes.
  // ---------------------------------------------------------------------------

  /// Se o texto for um CEP (8 números, com ou sem hífen), devolve só os números.
  static String? onlyCep(String text) {
    final trimmed = text.trim();
    if (!RegExp(r'^\d{5}-?\d{3}$').hasMatch(trimmed)) return null;
    return trimmed.replaceAll('-', '');
  }

  /// Siglas dos estados (o Nominatim devolve o nome por extenso).
  static const Map<String, String> stateCodes = {
    'Acre': 'AC', 'Alagoas': 'AL', 'Amapá': 'AP', 'Amazonas': 'AM', 'Bahia': 'BA',
    'Ceará': 'CE', 'Distrito Federal': 'DF', 'Espírito Santo': 'ES', 'Goiás': 'GO',
    'Maranhão': 'MA', 'Mato Grosso': 'MT', 'Mato Grosso do Sul': 'MS',
    'Minas Gerais': 'MG', 'Pará': 'PA', 'Paraíba': 'PB', 'Paraná': 'PR',
    'Pernambuco': 'PE', 'Piauí': 'PI', 'Rio de Janeiro': 'RJ',
    'Rio Grande do Norte': 'RN', 'Rio Grande do Sul': 'RS', 'Rondônia': 'RO',
    'Roraima': 'RR', 'Santa Catarina': 'SC', 'São Paulo': 'SP', 'Sergipe': 'SE',
    'Tocantins': 'TO',
  };

  /// Converte um item do Nominatim em [GeoPlace] com rótulo curto:
  /// "Rua Exemplo, Centro · Rio de Janeiro · RJ".
  static GeoPlace placeFromNominatim(Map<String, dynamic> json) {
    final address = (json['address'] as Map<String, dynamic>?) ?? const {};
    final city = (address['city'] ?? address['town'] ?? address['village'] ??
        address['municipality']) as String?;
    final stateName = address['state'] as String?;
    final state = stateCodes[stateName] ?? stateName;
    final street = address['road'] as String?;
    final district = (address['suburb'] ?? address['neighbourhood']) as String?;

    final firstPart = [street, district].whereType<String>().join(', ');
    final label = [
      if (firstPart.isNotEmpty) firstPart,
      ?city, // "?": só entra na lista se não for nulo
      ?state,
    ].join(' · ');

    return GeoPlace(
      latitude: double.tryParse('${json['lat']}') ?? 0,
      longitude: double.tryParse('${json['lon']}') ?? 0,
      label: label.isEmpty ? (json['display_name'] as String? ?? 'Local encontrado') : label,
      city: city,
      state: state,
    );
  }
}
