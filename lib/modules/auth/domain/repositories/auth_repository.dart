// =============================================================================
// modules/auth/domain/repositories/auth_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO de AUTENTICAÇÃO (camada de DOMÍNIO).
//
// Autenticação = provar QUEM é o usuário (login com e-mail e senha).
// O contrato define as operações; a implementação usa o Supabase Auth.
// =============================================================================

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// Operações de login, cadastro e saída.
abstract class AuthRepository {
  /// "Fluxo" (Stream) que avisa sempre que o usuário logado muda:
  /// emite o id do usuário ao entrar e `null` ao sair.
  Stream<String?> get userIdChanges;

  /// Id do usuário logado agora (ou `null` se ninguém estiver logado).
  String? get currentUserId;

  /// Entra com e-mail e senha.
  /// `Unit` significa "sucesso, sem valor para devolver".
  Future<Either<Failure, Unit>> signIn({
    required String email,
    required String password,
  });

  /// Cria uma conta nova com os papéis escolhidos.
  ///
  /// Devolve `true` se o Supabase exigir a CONFIRMAÇÃO do e-mail antes do
  /// primeiro login, ou `false` se o usuário já entrou automaticamente.
  Future<Either<Failure, bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool isProfessional,
    required bool isRecruiter,
  });

  /// Sai da conta (encerra a sessão neste aparelho).
  Future<Either<Failure, Unit>> signOut();
}
