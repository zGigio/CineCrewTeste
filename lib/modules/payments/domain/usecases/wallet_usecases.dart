// =============================================================================
// modules/payments/domain/usecases/wallet_usecases.dart
// -----------------------------------------------------------------------------
// CASOS DE USO DA CARTEIRA:
//   * SavePayoutAccountUseCase -> valida e salva a conta para receber;
//   * RequestWithdrawalUseCase -> valida e pede o saque (Pix ou TED).
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payout_account.dart';
import '../entities/wallet.dart';
import '../payout_validators.dart';
import '../repositories/wallet_repository.dart';

class SavePayoutAccountParams extends Equatable {
  final String userId;
  final PayoutAccount account;

  const SavePayoutAccountParams({required this.userId, required this.account});

  @override
  List<Object?> get props => [userId, account];
}

@injectable
class SavePayoutAccountUseCase implements UseCase<Unit, SavePayoutAccountParams> {
  final WalletRepository repository;

  SavePayoutAccountUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SavePayoutAccountParams params) async {
    final error = PayoutValidators.account(params.account);
    if (error != null) return Left(ValidationFailure(error));
    return repository.savePayoutAccount(params.userId, params.account);
  }
}

class WithdrawalParams extends Equatable {
  final double amount;
  final WithdrawalMethod method;

  /// Saldo disponível no momento (conferido de novo no banco).
  final double balance;

  /// Conta cadastrada (`null` = não cadastrou).
  final PayoutAccount? account;

  const WithdrawalParams({
    required this.amount,
    required this.method,
    required this.balance,
    required this.account,
  });

  @override
  List<Object?> get props => [amount, method, balance, account];
}

@injectable
class RequestWithdrawalUseCase implements UseCase<Withdrawal, WithdrawalParams> {
  final WalletRepository repository;

  RequestWithdrawalUseCase(this.repository);

  @override
  Future<Either<Failure, Withdrawal>> call(WithdrawalParams params) async {
    final account = params.account;
    if (account == null) {
      return const Left(ValidationFailure('Cadastre sua conta para receber antes de sacar.'));
    }
    if (params.method == WithdrawalMethod.pix && !account.hasPix) {
      return const Left(ValidationFailure('Cadastre uma chave Pix para sacar via Pix.'));
    }
    if (params.method == WithdrawalMethod.ted && !account.hasBankAccount) {
      return const Left(ValidationFailure('Cadastre uma conta bancária para sacar via TED.'));
    }

    // Trabalha em CENTAVOS (inteiros) para evitar erros de arredondamento.
    final cents = (params.amount * 100).round();
    if (params.amount <= 0 || (params.amount * 100 - cents).abs() > 1e-6) {
      return const Left(ValidationFailure('Informe um valor de saque válido.'));
    }
    if (cents > (params.balance * 100).round()) {
      return const Left(ValidationFailure('Saldo insuficiente.'));
    }
    return repository.requestWithdrawal(cents / 100, params.method);
  }
}
