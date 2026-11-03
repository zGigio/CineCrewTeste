// =============================================================================
// modules/jobs/presentation/cubit/job_search_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA BUSCA DE VAGAS.
//
// Recebe o filtro (Onde + Quando + Função), chama o caso de uso e emite:
//   carregando -> sucesso (lista de vagas) ou falha (mensagem).
// A tela apenas "desenha" o estado atual.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_search_filter.dart';
import '../../domain/usecases/search_jobs_usecase.dart';

/// `@injectable` (factory): cada tela de busca recebe um cubit novo.
@injectable
class JobSearchCubit extends Cubit<ListState<Job>> {
  final SearchJobsUseCase _searchJobs;

  JobSearchCubit(this._searchJobs) : super(const ListState<Job>());

  /// Executa a busca com o filtro informado.
  Future<void> search(JobSearchFilter filter) async {
    emit(state.toLoading());
    final result = await _searchJobs(filter);
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (jobs) => emit(state.toSuccess(jobs)),
    );
  }
}
