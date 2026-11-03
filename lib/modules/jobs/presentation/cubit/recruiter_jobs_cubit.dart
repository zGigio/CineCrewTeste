// =============================================================================
// modules/jobs/presentation/cubit/recruiter_jobs_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DE "MINHAS VAGAS" (visão do contratante).
// Carrega as vagas publicadas e permite encerrar uma vaga.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';

@injectable
class RecruiterJobsCubit extends Cubit<ListState<Job>> {
  final JobRepository _repository;

  /// Id do contratante cujas vagas estão sendo exibidas.
  String? _recruiterId;

  RecruiterJobsCubit(this._repository) : super(const ListState<Job>());

  /// Carrega (ou recarrega) as vagas do contratante.
  Future<void> load(String recruiterId) async {
    _recruiterId = recruiterId;
    emit(state.toLoading());
    final result = await _repository.getRecruiterJobs(recruiterId);
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (jobs) => emit(state.toSuccess(jobs)),
    );
  }

  /// Recarrega a lista (usado no "puxar para atualizar").
  Future<void> refresh() async {
    final id = _recruiterId;
    if (id != null) await load(id);
  }

  /// Encerra a vaga (ela deixa de aparecer nas buscas).
  /// Devolve uma mensagem de erro, ou `null` se deu certo.
  Future<String?> closeJob(Job job) async {
    final result = await _repository.updateJobStatus(job.id, JobStatus.closed);
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}
