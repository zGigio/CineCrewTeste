// =============================================================================
// modules/payments/domain/repositories/wallet_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO da carteira: extrato, conta para receber e saques.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/error/failures.dart';
import '../entities/payout_account.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  /// Extrato em TEMPO REAL, do mais recente para o mais antigo.
  Stream<List<WalletEntry>> watchEntries(String userId);

  /// Conta para receber do usuário (`null` = ainda não cadastrou).
  Future<Either<Failure, PayoutAccount?>> getPayoutAccount(String userId);

  /// Cria ou atualiza a conta para receber.
  Future<Either<Failure, Unit>> savePayoutAccount(String userId, PayoutAccount account);

  /// Pede um saque (simulado) para a conta cadastrada.
  Future<Either<Failure, Withdrawal>> requestWithdrawal(double amount, WithdrawalMethod method);
}
