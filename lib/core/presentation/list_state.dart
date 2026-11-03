// =============================================================================
// core/presentation/list_state.dart
// -----------------------------------------------------------------------------
// ESTADO GENÉRICO DE LISTAS (usado pelos Cubits de vagas, candidaturas...).
//
// Quase toda tela de lista passa pelos mesmos momentos:
//   inicial -> carregando -> sucesso (com itens) ou falha (com mensagem).
// Em vez de criar uma classe de estado para cada tela, usamos uma só,
// GENÉRICA: `ListState<Job>`, `ListState<JobApplication>` etc.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Situação do carregamento.
enum LoadStatus { initial, loading, success, failure }

/// Estado de uma lista de itens do tipo [T].
class ListState<T> extends Equatable {
  final LoadStatus status;
  final List<T> items;
  final String? errorMessage;

  const ListState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  /// Atalhos usados pelas telas.
  bool get isLoading => status == LoadStatus.loading;
  bool get isEmpty => status == LoadStatus.success && items.isEmpty;

  /// Estado "carregando", mantendo os itens atuais na tela (evita "piscar").
  ListState<T> toLoading() => ListState<T>(status: LoadStatus.loading, items: items);

  /// Estado de sucesso com a nova lista.
  ListState<T> toSuccess(List<T> newItems) =>
      ListState<T>(status: LoadStatus.success, items: newItems);

  /// Estado de falha com a mensagem de erro.
  ListState<T> toFailure(String message) =>
      ListState<T>(status: LoadStatus.failure, items: items, errorMessage: message);

  @override
  List<Object?> get props => [status, items, errorMessage];
}
