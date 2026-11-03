// =============================================================================
// modules/talent_search/domain/repositories/talent_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO DO REPOSITÓRIO (camada de DOMÍNIO).
//
// O domínio diz O QUE precisa ("buscar talentos por raio"), mas não COMO
// (API, banco local, cache...). O "como" fica na camada de dados, na classe
// TalentRepositoryImpl. Isso é a Inversão de Dependência (o "D" do SOLID).
// =============================================================================

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/professional_entity.dart';

/// Contrato abstrato do repositório do Banco de Talentos.
/// Define os métodos de busca e recuperação de perfis técnicos.
abstract class TalentRepository {
  /// Realiza a BUSCA ESPACIAL: encontra profissionais dentro de um raio
  /// (em km) a partir de um ponto (latitude/longitude), podendo filtrar
  /// por uma habilidade técnica (ex.: "Steadicam").
  ///
  /// Retorna um [Either] contendo uma [Failure] em caso de erro,
  /// ou uma lista de [ProfessionalEntity] com a distância já calculada.
  Future<Either<Failure, List<ProfessionalEntity>>> searchByRadius({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? skill,
  });

  /// Busca o perfil detalhado de um profissional pelo seu [id].
  Future<Either<Failure, ProfessionalEntity>> getTalentById(String id);
}
