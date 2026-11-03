// =============================================================================
// modules/explore/domain/usecases/explore_usecases.dart
// -----------------------------------------------------------------------------
// CASOS DE USO do modo Contratar:
//   * SearchTalentsUseCase -> valida os critérios e busca (TEL12);
//   * SaveProjectUseCase   -> valida e salva o projeto (TEL11/TEL15).
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../entities/search_criteria.dart';
import '../entities/talent_result.dart';
import '../repositories/explore_repository.dart';
import '../search_rules.dart';

@injectable
class SearchTalentsUseCase implements UseCase<List<TalentResult>, SearchCriteria> {
  final ExploreRepository repository;

  SearchTalentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TalentResult>>> call(SearchCriteria criteria) async {
    final errors = SearchRules.validate(criteria);
    if (errors.isNotEmpty) return Left(ValidationFailure(errors.values.first));
    return repository.searchTalents(criteria);
  }
}

@injectable
class SaveProjectUseCase implements UseCase<Project, Project> {
  final ExploreRepository repository;

  SaveProjectUseCase(this.repository);

  @override
  Future<Either<Failure, Project>> call(Project project) async {
    final name = project.name.trim();
    if (name.isEmpty) return const Left(ValidationFailure('Dê um nome ao projeto.'));
    final errors = SearchRules.validate(
      SearchCriteria(
        place: project.place,
        specialties: project.specialties,
        radiusKm: project.radiusKm,
        projectName: name,
      ),
    );
    if (errors.isNotEmpty) return Left(ValidationFailure(errors.values.first));
    return repository.saveProject(
      Project(
        id: project.id,
        name: name,
        place: project.place,
        radiusKm: project.radiusKm,
        specialties: project.specialties,
      ),
    );
  }
}
