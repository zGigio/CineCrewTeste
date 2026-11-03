// =============================================================================
// core/services/location/location_service.dart
// -----------------------------------------------------------------------------
// SERVIÇO DE LOCALIZAÇÃO (GPS) — base da "Computação Espacial" do app.
//
// Responsável por obter a latitude/longitude atual do celular. Essa coordenada
// é o CENTRO da busca de profissionais por raio (ex.: "técnicos de som a até
// 10 km de mim").
// =============================================================================

import 'package:fpdart/fpdart.dart';

// Geolocator: plugin que acessa o GPS nativo do Android/iOS.
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';

/// CONTRATO (interface) do serviço de localização.
///
/// O resto do app depende apenas deste contrato, e não do Geolocator.
/// Se um dia trocarmos de plugin, só a implementação muda.
abstract class LocationService {
  /// Obtém a posição geográfica atual do dispositivo.
  /// Retorna `Right(Position)` em caso de sucesso ou
  /// `Left(LocationFailure)` se o GPS estiver desligado / sem permissão.
  Future<Either<Failure, Position>> getCurrentPosition();
}

/// Implementação concreta usando o pacote [Geolocator].
///
/// `@LazySingleton(as: LocationService)`: registra esta classe no GetIt,
/// mas quem pedir `LocationService` recebe esta implementação.
@LazySingleton(as: LocationService)
class LocationServiceImpl implements LocationService {
  @override
  Future<Either<Failure, Position>> getCurrentPosition() async {
    try {
      // 1. Verifica se o GPS (serviço de localização) está LIGADO no aparelho.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(
          LocationFailure('O serviço de GPS está desativado no seu dispositivo.'),
        );
      }

      // 2. Verifica se o app já tem PERMISSÃO para acessar a localização.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Ainda não tem: exibe a janela do Android pedindo permissão.
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(
            LocationFailure('Permissão de acesso à localização negada pelo usuário.'),
          );
        }
      }

      // 3. "deniedForever": o usuário marcou "não perguntar novamente".
      //    O app não pode mais pedir; só o usuário, nas configurações.
      if (permission == LocationPermission.deniedForever) {
        return const Left(
          LocationFailure(
            'Permissão de localização negada permanentemente. '
            'Ative nas configurações do dispositivo.',
          ),
        );
      }

      // 4. Tudo certo: captura a posição atual.
      //    - accuracy.high: usa o GPS com alta precisão (poucos metros);
      //    - timeLimit: desiste após 15 segundos sem sinal.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return Right(position);
    } catch (e) {
      // Qualquer outro erro (ex.: tempo esgotado) vira uma LocationFailure.
      return Left(
        LocationFailure('Erro ao capturar coordenadas do dispositivo: $e'),
      );
    }
  }
}
