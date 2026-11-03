// =============================================================================
// modules/jobs/domain/usecases/search_jobs_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: BUSCAR VAGAS (Onde + Quando + Função).
//
// Antes de consultar o banco, valida as REGRAS DE NEGÓCIO da busca:
//   - coordenadas dentro dos limites do planeta;
//   - raio entre 1 e 500 km;
//   - data final não pode ser anterior à inicial.
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../entities/job_search_filter.dart';
import '../repositories/job_repository.dart';

@injectable
class SearchJobsUseCase implements UseCase<List<Job>, JobSearchFilter> {
  /// Limites do raio de busca (em km).
  static const int minRadiusKm = 1;
  static const int maxRadiusKm = 500;

  final JobRepository repository;

  SearchJobsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Job>>> call(JobSearchFilter filter) async {
    if (filter.latitude < -90 || filter.latitude > 90 ||
        filter.longitude < -180 || filter.longitude > 180) {
      return const Left(ValidationFailure('Localização inválida para a busca.'));
    }

    if (filter.radiusKm < minRadiusKm || filter.radiusKm > maxRadiusKm) {
      return const Left(
        ValidationFailure('O raio deve ficar entre $minRadiusKm e $maxRadiusKm km.'),
      );
    }

    final from = filter.dateFrom;
    final to = filter.dateTo;
    if (from != null && to != null && to.isBefore(from)) {
      return const Left(
        ValidationFailure('A data final não pode ser anterior à data inicial.'),
      );
    }

    return repository.searchJobs(filter);
  }
}
