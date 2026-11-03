// =============================================================================
// modules/talent_search/presentation/cubit/talent_search_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA BUSCA DE TALENTOS (visão do contratante).
// Chama o caso de uso SearchTalentsByRadiusUseCase, que consulta a função
// espacial `search_professionals` (PostGIS) no Supabase.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/usecases/search_talents_by_radius_usecase.dart';

@injectable
class TalentSearchCubit extends Cubit<ListState<ProfessionalEntity>> {
  final SearchTalentsByRadiusUseCase _searchTalents;

  TalentSearchCubit(this._searchTalents)
      : super(const ListState<ProfessionalEntity>());

  Future<void> search(SearchParams params) async {
    emit(state.toLoading());
    final result = await _searchTalents(params);
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (professionals) => emit(state.toSuccess(professionals)),
    );
  }
}
