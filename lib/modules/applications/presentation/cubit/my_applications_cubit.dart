// =============================================================================
// modules/applications/presentation/cubit/my_applications_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT "MINHAS CANDIDATURAS" (visão do profissional).
// Carrega as candidaturas, permite cancelar as pendentes e responder
// (aceitar/recusar) às propostas de contratação.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../../domain/usecases/respond_to_offer_usecase.dart';

@injectable
class MyApplicationsCubit extends Cubit<ListState<JobApplication>> {
  final ApplicationRepository _repository;
  final RespondToOfferUseCase _respondToOffer;
  String? _professionalId;

  MyApplicationsCubit(this._repository, this._respondToOffer)
      : super(const ListState<JobApplication>());

  Future<void> load(String professionalId) async {
    _professionalId = professionalId;
    emit(state.toLoading());
    final result = await _repository.getMyApplications(professionalId);
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (applications) => emit(state.toSuccess(applications)),
    );
  }

  Future<void> refresh() async {
    final id = _professionalId;
    if (id != null) await load(id);
  }

  /// Cancela a candidatura pendente. Devolve o erro, ou `null` se deu certo.
  Future<String?> cancel(JobApplication application) async {
    final result = await _repository.cancel(application.id);
    return result.fold(
      (failure) => failure.message,
      (_) {
        // Remove da lista na hora, sem buscar tudo de novo.
        emit(
          state.toSuccess(
            state.items.where((item) => item.id != application.id).toList(),
          ),
        );
        return null;
      },
    );
  }

  /// Aceita ([accept] = true) ou recusa a proposta.
  /// Devolve o erro, ou `null` se deu certo.
  Future<String?> respondToOffer(JobApplication application, {required bool accept}) async {
    final result = await _respondToOffer(
      RespondToOfferParams(application: application, accept: accept),
    );
    return result.fold(
      (failure) => failure.message,
      (newStatus) {
        final updated = state.items
            .map((item) => item.id == application.id ? item.withStatus(newStatus) : item)
            .toList();
        emit(state.toSuccess(updated));
        return null;
      },
    );
  }
}
