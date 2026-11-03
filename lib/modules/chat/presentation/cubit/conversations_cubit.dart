// =============================================================================
// modules/chat/presentation/cubit/conversations_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA LISTA DE CONVERSAS (aba "Mensagens").
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/presentation/list_state.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

@injectable
class ConversationsCubit extends Cubit<ListState<Conversation>> {
  final ChatRepository _repository;

  ConversationsCubit(this._repository) : super(const ListState<Conversation>());

  /// Carrega (ou recarrega) a lista de conversas.
  Future<void> load() async {
    emit(state.toLoading());
    final result = await _repository.getConversations();
    result.fold(
      (failure) => emit(state.toFailure(failure.message)),
      (conversations) => emit(state.toSuccess(conversations)),
    );
  }
}
