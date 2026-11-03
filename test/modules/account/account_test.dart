// =============================================================================
// test/modules/account/account_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 13: modo Profissional e Conta.
//   * a sessão abre no ÚLTIMO MODO usado (P20) e guarda o modo ao trocar;
//   * conta desativada vai para o estado "deactivated" (TEL02-E2);
//   * cartão de visibilidade do Painel (TEL16): verde só com tudo completo.
// Rodar com: flutter test
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:audiovisual_app/modules/auth/presentation/cubit/session_cubit.dart';
import 'package:audiovisual_app/modules/auth/presentation/cubit/session_state.dart';
import 'package:audiovisual_app/modules/professional/presentation/widgets/visibility_status_card.dart';
import 'package:audiovisual_app/modules/profile/domain/entities/user_profile.dart';
import 'package:audiovisual_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Right, Unit, unit;

/// Login FALSO: o teste decide quando "alguém entrou".
class FakeAuthRepository implements AuthRepository {
  final controller = StreamController<String?>();

  @override
  Stream<String?> get userIdChanges => controller.stream;

  @override
  String? get currentUserId => null;

  @override
  Future<Either<Failure, Unit>> signIn({required String email, required String password}) async =>
      const Right(unit);

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

/// Perfil FALSO: devolve o perfil configurado e guarda o último modo salvo.
class FakeProfileRepository implements ProfileRepository {
  UserProfile profile;
  String? savedMode;

  /// Se preenchido, getProfile falha com esta mensagem.
  String? failWith;

  FakeProfileRepository(this.profile);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async =>
      failWith != null ? Left(ServerFailure(message: failWith!)) : Right(profile);

  @override
  Future<Either<Failure, Unit>> saveLastMode(String userId, String mode) async {
    savedMode = mode;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async => Right(profile);

  @override
  Future<Either<Failure, DateTime>> acceptLocationTerms(String termsVersion) async =>
      Right(DateTime(2026));

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) async =>
      const Right('');

  @override
  Future<Either<Failure, String>> uploadCover({
    required String userId,
    required Uint8List bytes,
  }) async =>
      const Right('');

  @override
  Future<Either<Failure, String>> uploadResume({
    required String userId,
    required Uint8List bytes,
  }) async =>
      const Right('');

  @override
  Future<Either<Failure, String>> getResumeUrl(String resumePath) async => const Right('');
}

/// Espera o cubit processar o "login" (eventos assíncronos).
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('Sessão', () {
    test('abre no último modo usado (P20) e guarda ao trocar', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository(
        const UserProfile(
          id: 'u1',
          fullName: 'Leo',
          isProfessional: true,
          isRecruiter: true,
          lastMode: 'recruiter',
        ),
      );
      final cubit = SessionCubit(auth, profiles);
      auth.controller.add('u1');
      await settle();

      expect(cubit.state.status, SessionStatus.authenticated);
      expect(cubit.state.mode, AppMode.recruiter);

      cubit.switchMode(AppMode.professional);
      expect(cubit.state.mode, AppMode.professional);
      expect(profiles.savedMode, 'professional');
      await cubit.close();
    });

    test('último modo sem o perfil correspondente é ignorado', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository(
        const UserProfile(id: 'u1', fullName: 'Leo', isProfessional: true, lastMode: 'recruiter'),
      );
      final cubit = SessionCubit(auth, profiles);
      auth.controller.add('u1');
      await settle();
      expect(cubit.state.mode, AppMode.professional);
      await cubit.close();
    });

    test('conta desativada vai para a reativação (TEL02-E2)', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository(
        UserProfile(id: 'u1', fullName: 'Leo', deactivatedAt: DateTime(2026, 10, 1)),
      );
      final cubit = SessionCubit(auth, profiles);
      auth.controller.add('u1');
      await settle();
      expect(cubit.state.status, SessionStatus.deactivated);
      await cubit.close();
    });

    test('perfil que não carrega mostra o erro (não volta às boas-vindas)', () async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository(const UserProfile(id: 'u1', fullName: 'Leo'))
        ..failWith = 'banco desatualizado';
      final cubit = SessionCubit(auth, profiles);
      auth.controller.add('u1');
      await settle();
      expect(cubit.state.status, SessionStatus.loadError);
      expect(cubit.state.errorMessage, 'banco desatualizado');
      await cubit.close();
    });

    test('AppMode.fromValue', () {
      expect(AppMode.fromValue('recruiter'), AppMode.recruiter);
      expect(AppMode.fromValue('qualquer'), isNull);
    });
  });

  group('Cartão de visibilidade (TEL16)', () {
    Future<void> pumpCard(WidgetTester tester, UserProfile profile) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: VisibilityStatusCard(profile: profile, portfolioCount: 0)),
          ),
        );

    testWidgets('perfil completo aparece nas buscas', (tester) async {
      await pumpCard(
        tester,
        UserProfile(
          id: 'u1',
          fullName: 'Leo',
          primaryRole: 'Videomaker',
          latitude: -22.9,
          longitude: -43.2,
          locationConsentAt: DateTime(2026, 9, 12),
        ),
      );
      expect(find.text('Seu perfil aparece nas buscas'), findsOneWidget);
    });

    testWidgets('sem aceite não aparece nas buscas', (tester) async {
      await pumpCard(
        tester,
        const UserProfile(
          id: 'u1',
          fullName: 'Leo',
          primaryRole: 'Videomaker',
          latitude: -22.9,
          longitude: -43.2,
        ),
      );
      expect(find.text('Seu perfil ainda não aparece nas buscas'), findsOneWidget);
    });
  });
}
