// =============================================================================
// modules/chat/presentation/cubit/chat_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DE UMA CONVERSA (tela de mensagens).
//
//   1. Escuta o fluxo em TEMPO REAL das mensagens da conversa;
//   2. Sempre que chegam mensagens novas do outro, marca como lidas;
//   3. Envia mensagens pelo SendMessageUseCase.
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';

/// Estado da tela de conversa.
class ChatState extends Equatable {
  final List<ChatMessage> messages;

  /// Ainda esperando a primeira lista de mensagens?
  final bool isLoading;

  /// Enviando uma mensagem agora?
  final bool isSending;

  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
  });

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, bool? isSending}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isSending];
}

@injectable
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;
  final SendMessageUseCase _sendMessage;

  StreamSubscription<List<ChatMessage>>? _subscription;
  late String _conversationId;
  late String _userId;

  ChatCubit(this._repository, this._sendMessage) : super(const ChatState());

  /// Abre a conversa: começa a escutar as mensagens em tempo real.
  void open({required String conversationId, required String userId}) {
    _conversationId = conversationId;
    _userId = userId;
    _subscription?.cancel();
    _subscription = _repository.watchMessages(conversationId).listen(
      (messages) {
        emit(state.copyWith(messages: messages, isLoading: false));
        _markReceivedAsRead(messages);
      },
      // Se o tempo real falhar, apenas para de mostrar o carregamento.
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  /// Marca como lidas as mensagens recebidas que ainda não foram lidas.
  void _markReceivedAsRead(List<ChatMessage> messages) {
    final hasUnread = messages.any((m) => !m.isMine(_userId) && !m.isRead);
    if (hasUnread) {
      _repository.markAsRead(conversationId: _conversationId, userId: _userId);
    }
  }

  /// Envia o texto digitado. Devolve a mensagem de erro, ou `null` se deu certo.
  /// A mensagem enviada aparece sozinha na lista, pelo fluxo em tempo real.
  Future<String?> send(String text) async {
    emit(state.copyWith(isSending: true));
    final result = await _sendMessage(
      SendMessageParams(conversationId: _conversationId, senderId: _userId, content: text),
    );
    emit(state.copyWith(isSending: false));
    return result.fold((failure) => failure.message, (_) => null);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
