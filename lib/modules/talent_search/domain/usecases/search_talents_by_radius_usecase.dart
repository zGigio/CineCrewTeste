// =============================================================================
// modules/talent_search/domain/usecases/search_talents_by_radius_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: "Buscar talentos por raio geográfico".
//
// É a principal funcionalidade do app. O caso de uso:
//   1. Recebe os parâmetros da busca (ponto central, raio, habilidade);
//   2. VALIDA as regras de negócio (coordenadas e raio válidos);
//   3. Pede ao repositório os profissionais encontrados.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/professional_entity.dart';
import '../repositories/talent_repository.dart';

/// Parâmetros de entrada da busca espacial.
class SearchParams extends Equatable {
  /// Latitude do ponto central da busca (normalmente a posição do usuário).
  final double latitude;

  /// Longitude do ponto central da busca.
  final double longitude;

  /// Raio da busca em quilômetros (ex.: 10 = profissionais a até 10 km).
  final double radiusInKm;

  /// Filtro opcional por habilidade/função (ex.: "Técnico de Som").
  final String? skill;

  const SearchParams({
    required this.latitude,
    required this.longitude,
    required this.radiusInKm,
    this.skill,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusInKm, skill];
}

/// Caso de uso que executa a busca de profissionais por raio.
///
/// `@injectable`: registrado no GetIt como "factory" — uma NOVA instância é
/// criada cada vez que for solicitada (casos de uso não guardam estado).
@injectable
class SearchTalentsByRadiusUseCase
    implements UseCase<List<ProfessionalEntity>, SearchParams> {
  /// Raio máximo permitido (em km), para evitar buscas pesadas demais.
  static const int maxRadiusInKm = 500;

  /// Repositório recebido por injeção de dependência (via construtor).
  final TalentRepository repository;

  SearchTalentsByRadiusUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProfessionalEntity>>> call(
    SearchParams params,
  ) async {
    // --- Regras de negócio (validação antes de chamar o servidor) ---

    // Latitude válida vai de -90 a 90 graus.
    if (params.latitude < -90 || params.latitude > 90) {
      return const Left(ValidationFailure('Latitude inválida.'));
    }

    // Longitude válida vai de -180 a 180 graus.
    if (params.longitude < -180 || params.longitude > 180) {
      return const Left(ValidationFailure('Longitude inválida.'));
    }

    // O raio precisa ser positivo e não pode passar do limite máximo.
    if (params.radiusInKm <= 0 || params.radiusInKm > maxRadiusInKm) {
      return const Left(
        ValidationFailure(
          'O raio de busca deve ser maior que 0 e no máximo $maxRadiusInKm km.',
        ),
      );
    }

    // Remove espaços extras do filtro; se ficar vazio, ignora o filtro.
    final skill = params.skill?.trim();

    // --- Delegação ao repositório ---
    return repository.searchByRadius(
      latitude: params.latitude,
      longitude: params.longitude,
      radiusInKm: params.radiusInKm,
      skill: (skill == null || skill.isEmpty) ? null : skill,
    );
  }
}
