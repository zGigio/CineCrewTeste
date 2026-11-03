// =============================================================================
// modules/applications/presentation/cubit/job_applications_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT "CANDIDATOS DA VAGA" (visão do contratante).
// Carrega os candidatos e conduz o processo seletivo de cada um:
// aprovar para entrevista, reprovar ou enviar proposta de contratação.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../../domain/usecases/update_application_status_usecase.dart';

@injectable
class JobApplicationsCubit extends Cubit<ListState<JobApplication>> {
  final ApplicationRepository _repository;
  final UpdateApplicationStatusUseCase _updateStatus;
  String? _jobId;

  JobApplicationsCubit(this._repository, this._updateStatus)
      : super(const ListState<JobApplication>());

  Future<void> load(String jobId) async {
    _jobId = jobId;
    emit(state.toLoading());
    final result = await _repository.getApplicationsForJob(jobId);
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (applications) => emit(state.toSuccess(applications)),
    );
  }

  Future<void> refresh() async {
    final id = _jobId;
    if (id != null) await load(id);
  }

  /// Muda o status do candidato. Devolve a mensagem de erro, ou `null`.
  Future<String?> changeStatus(
    JobApplication application,
    ApplicationStatus newStatus,
  ) async {
    final result = await _updateStatus(
      UpdateStatusParams(application: application, newStatus: newStatus),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        // Atualiza só o candidato alterado na lista exibida.
        final updated = state.items
            .map((item) => item.id == application.id ? item.withStatus(newStatus) : item)
            .toList();
        emit(state.toSuccess(updated));
        return null;
      },
    );
  }
}
