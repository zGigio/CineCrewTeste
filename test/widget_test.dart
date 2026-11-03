// =============================================================================
// test/widget_test.dart
// -----------------------------------------------------------------------------
// TESTES DE WIDGET das telas de acesso (Boas-vindas, Entrar, Criar conta).
//
// Monta a tela num ambiente simulado (sem celular e sem internet) e verifica
// se as validações do formulário aparecem corretamente.
// Para rodar: `flutter test`
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:audiovisual_app/core/di/injection.dart';
import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:audiovisual_app/modules/auth/presentation/pages/login_page.dart';
import 'package:audiovisual_app/modules/auth/presentation/pages/sign_up_page.dart';
import 'package:audiovisual_app/modules/auth/presentation/pages/welcome_page.dart';

/// Repositório FALSO de autenticação (um "dublê" de teste).
/// Substitui o Supabase: assim o teste não depende de internet.
class FakeAuthRepository implements AuthRepository {
  /// Guarda quantas vezes o login foi chamado, para conferir no teste.
  int signInCalls = 0;

  @override
  Stream<String?> get userIdChanges => const Stream.empty();

  @override
  String? get currentUserId => null;

  @override
  Future<Either<Failure, Unit>> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    return const Left(AuthFailure('E-mail ou senha incorretos.'));
  }

  @override
  Future<Either<Failure, bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool isProfessional,
    required bool isRecruiter,
  }) async =>
      const Right(false);

  @override
  Future<Either<Failure, Unit>> signOut() async => const Right(unit);
}

void main() {
  late FakeAuthRepository fakeAuth;

  // Antes de cada teste: registra o repositório falso no GetIt.
  setUp(() {
    fakeAuth = FakeAuthRepository();
    getIt.registerSingleton<AuthRepository>(fakeAuth);
  });

  // Depois de cada teste: limpa o GetIt para o próximo teste.
  tearDown(() => getIt.reset());

  testWidgets('Mostra erros ao tentar entrar com campos vazios', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Toca no botão "Entrar" sem preencher nada. (O título da tela também é
    // "Entrar", então procuramos especificamente o BOTÃO.)
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    // As mensagens de validação devem aparecer...
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    // ...e o login NÃO deve ter sido chamado.
    expect(fakeAuth.signInCalls, 0);
  });

  testWidgets('Mostra a mensagem de erro do login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Preenche e-mail e senha válidos (no formato).
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@teste.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    // pumpAndSettle: espera as animações e chamadas assíncronas terminarem.
    await tester.pumpAndSettle();

    // O login foi chamado uma vez e o banner de erro (TEL02-E1) apareceu.
    expect(fakeAuth.signInCalls, 1);
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('Boas-vindas (TEL01) leva ao cadastro e ao login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    expect(find.text('A equipe certa, perto do set.'), findsOneWidget);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Crie sua conta'), findsOneWidget);
  });

  testWidgets('Cadastro (TEL03-E1) mostra os erros por campo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

    // Senha fora do padrão (curta e sem número).
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Use 8 ou mais caracteres, com letras e números.'), findsOneWidget);
  });
}
