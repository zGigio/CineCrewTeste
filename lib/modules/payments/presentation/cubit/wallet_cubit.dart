// =============================================================================
// modules/payments/presentation/cubit/wallet_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA CARTEIRA: extrato em tempo real, saldo, conta para receber e saque.
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/payout_account.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/wallet_usecases.dart';

class WalletState extends Equatable {
  final List<WalletEntry> entries;
  final bool isLoading;

  /// Conta para receber (`null` = não cadastrada).
  final PayoutAccount? account;

  /// Mensagem de erro ao carregar (ex.: sem internet).
  final String? errorMessage;

  const WalletState({
    this.entries = const [],
    this.isLoading = true,
    this.account,
    this.errorMessage,
  });

  /// Saldo disponível = soma do extrato.
  double get balance => walletBalance(entries);

  @override
  List<Object?> get props => [entries, isLoading, account, errorMessage];
}

@injectable
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _repository;
  final SavePayoutAccountUseCase _saveAccount;
  final RequestWithdrawalUseCase _withdraw;

  StreamSubscription<List<WalletEntry>>? _subscription;
  late String _userId;

  WalletCubit(this._repository, this._saveAccount, this._withdraw)
      : super(const WalletState());

  Future<void> open(String userId) async {
    _userId = userId;
    _subscription?.cancel();
    _subscription = _repository.watchEntries(userId).listen(
      (entries) => emit(_copy(entries: entries, isLoading: false)),
      onError: (_) => emit(_copy(isLoading: false)),
    );

    final result = await _repository.getPayoutAccount(userId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(_copy(errorMessage: failure.message)),
      (account) => emit(_copy(account: account)),
    );
  }

  /// Salva a conta. Devolve a mensagem de erro, ou `null` se deu certo.
  Future<String?> saveAccount(PayoutAccount account) async {
    final result = await _saveAccount(
      SavePayoutAccountParams(userId: _userId, account: account),
    );
    if (isClosed) return null;
    return result.fold((failure) => failure.message, (_) {
      emit(_copy(account: account));
      return null;
    });
  }

  /// Pede o saque. Devolve a mensagem de erro, ou `null` se deu certo.
  /// O novo saldo chega pelo extrato em tempo real.
  Future<String?> withdraw(double amount, WithdrawalMethod method) async {
    final result = await _withdraw(
      WithdrawalParams(
        amount: amount,
        method: method,
        balance: state.balance,
        account: state.account,
      ),
    );
    return result.fold((failure) => failure.message, (_) => null);
  }

  /// copyWith manual: mantém a conta e o extrato atuais quando não informados.
  WalletState _copy({
    List<WalletEntry>? entries,
    bool? isLoading,
    PayoutAccount? account,
    String? errorMessage,
  }) {
    return WalletState(
      entries: entries ?? state.entries,
      isLoading: isLoading ?? state.isLoading,
      account: account ?? state.account,
      errorMessage: errorMessage ?? state.errorMessage,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
