// =============================================================================
// modules/explore/presentation/explore_navigation.dart
// -----------------------------------------------------------------------------
// NAVEGAÇÃO DO MODO CONTRATAR.
//
// O ProjectsCubit é criado na tela principal (HomePage). Uma tela aberta
// com Navigator.push NÃO fica "dentro" da HomePage na árvore de widgets,
// então não enxergaria o cubit. Estas funções repassam o MESMO cubit para
// a tela nova com BlocProvider.value.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/search_criteria.dart';
import 'cubit/projects_cubit.dart';
import 'pages/define_search_page.dart';
import 'pages/results_page.dart';

/// Abre a TEL11 e devolve os critérios válidos (ou `null` se voltar).
Future<SearchCriteria?> openDefineSearch(
  BuildContext context, {
  SearchCriteria initial = const SearchCriteria(),
  bool validateOnOpen = false,
}) {
  final projects = context.read<ProjectsCubit>();
  return Navigator.of(context).push<SearchCriteria>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: projects,
        child: DefineSearchPage(initial: initial, validateOnOpen: validateOnOpen),
      ),
    ),
  );
}

/// Abre os resultados (TEL12/TEL13) já buscando.
Future<void> openResults(BuildContext context, SearchCriteria criteria) {
  final projects = context.read<ProjectsCubit>();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: projects,
        child: ResultsPage(criteria: criteria),
      ),
    ),
  );
}

/// Fluxo completo "definir busca -> resultados".
Future<void> defineAndSearch(
  BuildContext context, {
  SearchCriteria initial = const SearchCriteria(),
  bool validateOnOpen = false,
}) async {
  final criteria = await openDefineSearch(
    context,
    initial: initial,
    validateOnOpen: validateOnOpen,
  );
  if (criteria != null && context.mounted) await openResults(context, criteria);
}
