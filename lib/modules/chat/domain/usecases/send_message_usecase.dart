// =============================================================================
// modules/chat/domain/usecases/send_message_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: ENVIAR MENSAGEM NO CHAT.
//
// Regras: a mensagem não pode estar vazia (só espaços) e tem no máximo
// 2000 caracteres (mesmo limite da tabela `messages` no banco).
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SendMessageParams extends Equatable {
  final String conversationId;
  final String senderId;
  final String content;

  const SendMessageParams({
    required this.conversationId,
    required this.senderId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, senderId, content];
}

@injectable
class SendMessageUseCase implements UseCase<Unit, SendMessageParams> {
  static const int maxLength = 2000;

  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SendMessageParams params) async {
    final text = params.content.trim();
    if (text.isEmpty) {
      return const Left(ValidationFailure('Escreva uma mensagem.'));
    }
    if (text.length > maxLength) {
      return const Left(
        ValidationFailure('A mensagem deve ter no máximo $maxLength caracteres.'),
      );
    }
    return repository.sendMessage(
      conversationId: params.conversationId,
      senderId: params.senderId,
      content: text,
    );
  }
}
