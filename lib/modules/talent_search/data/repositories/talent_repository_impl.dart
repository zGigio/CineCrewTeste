// =============================================================================
// modules/talent_search/data/repositories/talent_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO DO REPOSITÓRIO (camada de DADOS).
//
// Cumpre o contrato [TalentRepository] definido no domínio. Seu papel é:
//   1. Chamar o Data Source;
//   2. Capturar exceções (ServerException) e "traduzi-las" em Failures;
//   3. Devolver sempre um Either: Left(Failure) ou Right(dados).
// Assim, as camadas de cima nunca recebem uma exceção "solta".
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/repositories/talent_repository.dart';
import '../datasources/talent_remote_data_source.dart';

/// `@LazySingleton(as: TalentRepository)`: quem pedir um `TalentRepository`
/// ao GetIt recebe esta implementação (uma única instância, criada sob demanda).
@LazySingleton(as: TalentRepository)
class TalentRepositoryImpl implements TalentRepository {
  /// Fonte de dados remota (API), recebida por injeção de dependência.
  final TalentRemoteDataSource remoteDataSource;

  TalentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ProfessionalEntity>>> searchByRadius({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? skill,
  }) async {
    try {
      final models = await remoteDataSource.searchByRadius(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radiusInKm,
        skill: skill,
      );
      // Sucesso: os Models SÃO entidades (herança), então podem ser
      // devolvidos diretamente como List<ProfessionalEntity>.
      return Right(models);
    } on ServerException catch (e) {
      // Erro conhecido do servidor -> ServerFailure.
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      // Qualquer outro erro não previsto -> UnexpectedFailure.
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfessionalEntity>> getTalentById(String id) async {
    try {
      final model = await remoteDataSource.getTalentById(id);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
