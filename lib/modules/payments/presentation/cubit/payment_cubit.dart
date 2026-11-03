// =============================================================================
// modules/payments/presentation/cubit/payment_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA TELA DE GARANTIA.
//   1. Escuta o pagamento da candidatura em TEMPO REAL;
//   2. Executa as ações (pagar, confirmar, disputar) pelos casos de uso.
// As ações devolvem a mensagem de erro, ou `null` se deu certo. O novo
// estado chega sozinho pelo tempo real.
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/escrow_usecases.dart';

class PaymentState extends Equatable {
  /// `null` = não existe pagamento para esta contratação.
  final Payment? payment;

  /// Esperando a primeira resposta do tempo real?
  final bool isLoading;

  /// Executando uma ação (botões ficam desabilitados)?
  final bool isBusy;

  const PaymentState({this.payment, this.isLoading = true, this.isBusy = false});

  PaymentState copyWith({Payment? payment, bool? isLoading, bool? isBusy}) {
    return PaymentState(
      payment: payment ?? this.payment,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [payment, isLoading, isBusy];
}

@injectable
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;
  final PayEscrowUseCase _pay;
  final ConfirmServiceUseCase _confirm;
  final OpenDisputeUseCase _dispute;

  StreamSubscription<Payment?>? _subscription;
  late String _userId;

  PaymentCubit(this._repository, this._pay, this._confirm, this._dispute)
      : super(const PaymentState());

  void watch({required String applicationId, required String userId}) {
    _userId = userId;
    _subscription?.cancel();
    _subscription = _repository.watchByApplication(applicationId).listen(
      // Aqui não usamos copyWith: o pagamento pode realmente ser `null`.
      (payment) => emit(PaymentState(payment: payment, isLoading: false, isBusy: state.isBusy)),
      onError: (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<String?> pay() => _run(_pay.call);

  Future<String?> confirmService() => _run(_confirm.call);

  Future<String?> openDispute(String reason) => _run(_dispute.call, reason: reason);

  /// Executa um caso de uso de garantia com o pagamento atual.
  Future<String?> _run(
    Future<Either<Failure, Payment>> Function(EscrowActionParams) action, {
    String reason = '',
  }) async {
    final payment = state.payment;
    if (payment == null) return 'Pagamento não encontrado.';

    emit(state.copyWith(isBusy: true));
    final result = await action(
      EscrowActionParams(payment: payment, userId: _userId, reason: reason),
    );
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(state.copyWith(isBusy: false));
        return failure.message;
      },
      (updated) {
        // Atualiza na hora (sem esperar o tempo real).
        emit(state.copyWith(payment: updated, isBusy: false));
        return null;
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
