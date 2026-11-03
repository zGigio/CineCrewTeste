// =============================================================================
// modules/explore/domain/repositories/explore_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do modo Contratar: buscar talentos e gerenciar projetos.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/error/failures.dart';
import '../entities/project.dart';
import '../entities/search_criteria.dart';
import '../entities/talent_result.dart';

abstract class ExploreRepository {
  /// Profissionais dentro do raio, do mais próximo ao mais distante.
  Future<Either<Failure, List<TalentResult>>> searchTalents(SearchCriteria criteria);

  /// Projetos do contratante logado (mais recentes primeiro).
  Future<Either<Failure, List<Project>>> getProjects();

  /// Cria (sem id) ou atualiza (com id) um projeto.
  Future<Either<Failure, Project>> saveProject(Project project);

  Future<Either<Failure, Unit>> deleteProject(String projectId);
}
