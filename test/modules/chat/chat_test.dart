// =============================================================================
// test/modules/chat/chat_test.dart
// -----------------------------------------------------------------------------
// TESTES do CHAT: regras de envio e o balão de mensagem.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/chat/domain/entities/chat_message.dart';
import 'package:audiovisual_app/modules/chat/domain/entities/conversation.dart';
import 'package:audiovisual_app/modules/chat/domain/repositories/chat_repository.dart';
import 'package:audiovisual_app/modules/chat/domain/usecases/send_message_usecase.dart';
import 'package:audiovisual_app/modules/chat/presentation/widgets/message_bubble.dart';

/// Repositório falso: guarda o último texto enviado.
class FakeChatRepository implements ChatRepository {
  String? lastSent;

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    lastSent = content;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async => const Right([]);

  @override
  Future<Either<Failure, Conversation?>> findConversation({
    required String jobId,
    required String otherUserId,
  }) async =>
      const Right(null);

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) => const Stream.empty();

  @override
  Future<Either<Failure, Unit>> markAsRead({
    required String conversationId,
    required String userId,
  }) async =>
      const Right(unit);
}

/// Encontra o Align DENTRO do balão (o Scaffold também usa Align internamente).
Finder _bubbleAlign() => find
    .descendant(of: find.byType(MessageBubble), matching: find.byType(Align))
    .first;

void main() {
  late FakeChatRepository repository;
  setUp(() => repository = FakeChatRepository());

  group('SendMessageUseCase', () {
    test('envia o texto sem os espaços das pontas', () async {
      final result = await SendMessageUseCase(repository)(
        const SendMessageParams(conversationId: 'c1', senderId: 'ana', content: '  Oi!  '),
      );
      expect(result.isRight(), isTrue);
      expect(repository.lastSent, 'Oi!');
    });

    test('recusa mensagem vazia', () async {
      final result = await SendMessageUseCase(repository)(
        const SendMessageParams(conversationId: 'c1', senderId: 'ana', content: '   '),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.lastSent, isNull);
    });

    test('recusa mensagem acima do limite', () async {
      final longText = 'a' * (SendMessageUseCase.maxLength + 1);
      final result = await SendMessageUseCase(repository)(
        SendMessageParams(conversationId: 'c1', senderId: 'ana', content: longText),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('MessageBubble', () {
    final message = ChatMessage(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'ana',
      content: 'Chego às 7h no set.',
      createdAt: DateTime(2030, 1, 10, 6, 45),
      readAt: DateTime(2030, 1, 10, 6, 50),
    );

    testWidgets('minha mensagem fica à direita e mostra o "visto"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MessageBubble(message: message, isMine: true))),
      );
      expect(find.text('Chego às 7h no set.'), findsOneWidget);
      expect(find.text('06:45'), findsOneWidget);
      // Lida = dois "vistos".
      expect(find.byIcon(Icons.done_all), findsOneWidget);
      final align = tester.widget<Align>(_bubbleAlign());
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('mensagem do outro fica à esquerda, sem "visto"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MessageBubble(message: message, isMine: false))),
      );
      expect(find.byIcon(Icons.done_all), findsNothing);
      final align = tester.widget<Align>(_bubbleAlign());
      expect(align.alignment, Alignment.centerLeft);
    });
  });

  test('ChatMessage.isMine identifica quem enviou', () {
    final message = ChatMessage(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'ana',
      content: 'Oi',
      createdAt: DateTime(2030),
    );
    expect(message.isMine('ana'), isTrue);
    expect(message.isMine('carla'), isFalse);
  });
}
