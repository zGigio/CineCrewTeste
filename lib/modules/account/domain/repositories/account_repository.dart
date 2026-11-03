// =============================================================================
// modules/account/domain/repositories/account_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO DA CONTA (TEL21 e TEL22): dados de login e privacidade.
// Vale para a conta INTEIRA, nos dois modos de uso.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/error/failures.dart';

abstract class AccountRepository {
  /// Troca o e-mail de login. O Supabase envia um link de confirmação para
  /// o e-mail novo; a troca só vale depois de confirmada.
  Future<Either<Failure, Unit>> updateEmail(String email);

  /// Troca a senha.
  Future<Either<Failure, Unit>> updatePassword(String password);

  /// Revoga o aceite do uso da localização (TEL22-E2): o perfil
  /// profissional deixa de aparecer nas buscas.
  Future<Either<Failure, Unit>> revokeLocationConsent();

  /// Desativa a conta (some das buscas e só entra para reativar).
  Future<Either<Failure, Unit>> deactivateAccount();

  /// Reativa a conta desativada (TEL02-E2).
  Future<Either<Failure, Unit>> reactivateAccount();

  /// Exclui DEFINITIVAMENTE a conta, os arquivos e os dados (TEL22-E1).
  Future<Either<Failure, Unit>> deleteAccount(String userId);
}
