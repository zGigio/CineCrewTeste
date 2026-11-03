// =============================================================================
// modules/explore/presentation/cubit/projects_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DOS PROJETOS (TEL15 e "Projetos recentes" do Explorar, TEL10).
// Fica num nível acima das duas abas, para as duas verem a mesma lista.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../domain/usecases/explore_usecases.dart';

@injectable
class ProjectsCubit extends Cubit<ListState<Project>> {
  final ExploreRepository _repository;
  final SaveProjectUseCase _saveProject;

  ProjectsCubit(this._repository, this._saveProject) : super(const ListState<Project>());

  Future<void> load() async {
    emit(state.toLoading());
    final result = await _repository.getProjects();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (projects) => emit(state.toSuccess(projects)),
    );
  }

  /// Salva e devolve o projeto gravado (com id), ou a mensagem de erro.
  Future<(Project?, String?)> save(Project project) async {
    final result = await _saveProject(project);
    if (isClosed) return (null, null);
    return result.fold<(Project?, String?)>(
      (failure) => (null, failure.message),
      (saved) {
        // O salvo vai para o topo (mais recente primeiro).
        final others = state.items.where((p) => p.id != saved.id);
        emit(state.toSuccess([saved, ...others]));
        return (saved, null);
      },
    );
  }

  /// Apaga o projeto. Devolve a mensagem de erro, ou `null`.
  Future<String?> delete(String projectId) async {
    final result = await _repository.deleteProject(projectId);
    if (isClosed) return null;
    return result.fold<String?>((failure) => failure.message, (_) {
      emit(state.toSuccess(state.items.where((p) => p.id != projectId).toList()));
      return null;
    });
  }
}
