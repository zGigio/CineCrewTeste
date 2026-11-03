// =============================================================================
// modules/explore/presentation/cubit/talent_results_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DOS RESULTADOS (TEL12 lista / TEL13 mapa).
//
//   carregando (TEL12-E1) -> sucesso | nenhum profissional (TEL12-E2)
//                         -> erro de conexão (TEL12-E3, "Tentar novamente")
//
// Guarda também os CRITÉRIOS (para a pílula de resumo e o painel de
// filtros) e o profissional SELECIONADO no mapa.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/search_criteria.dart';
import '../../domain/entities/talent_result.dart';
import '../../domain/usecases/explore_usecases.dart';

enum ResultsStatus { loading, success, failure }

class TalentResultsState extends Equatable {
  final SearchCriteria criteria;
  final ResultsStatus status;
  final List<TalentResult> results;
  final String? errorMessage;

  /// Profissional tocado no mapa (mostra o cartão embaixo).
  final String? selectedId;

  const TalentResultsState({
    required this.criteria,
    this.status = ResultsStatus.loading,
    this.results = const [],
    this.errorMessage,
    this.selectedId,
  });

  bool get isEmpty => status == ResultsStatus.success && results.isEmpty;

  TalentResult? get selected =>
      results.where((result) => result.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [criteria, status, results, errorMessage, selectedId];
}

@injectable
class TalentResultsCubit extends Cubit<TalentResultsState> {
  final SearchTalentsUseCase _searchTalents;

  TalentResultsCubit(this._searchTalents)
      : super(const TalentResultsState(criteria: SearchCriteria()));

  /// Faz (ou refaz) a busca com os critérios informados.
  Future<void> search(SearchCriteria criteria) async {
    emit(TalentResultsState(criteria: criteria)); // status = carregando
    final result = await _searchTalents(criteria);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TalentResultsState(
        criteria: criteria,
        status: ResultsStatus.failure,
        errorMessage: failure.message,
      )),
      (results) => emit(TalentResultsState(
        criteria: criteria,
        status: ResultsStatus.success,
        results: results,
        // No mapa, já deixa o mais próximo selecionado.
        selectedId: results.isEmpty ? null : results.first.id,
      )),
    );
  }

  /// "Tentar novamente" (TEL12-E3): a busca foi mantida.
  Future<void> retry() => search(state.criteria);

  void select(String id) {
    emit(TalentResultsState(
      criteria: state.criteria,
      status: state.status,
      results: state.results,
      errorMessage: state.errorMessage,
      selectedId: id,
    ));
  }
}
