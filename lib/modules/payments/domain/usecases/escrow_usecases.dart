// =============================================================================
// modules/payments/domain/usecases/escrow_usecases.dart
// -----------------------------------------------------------------------------
// CASOS DE USO DA GARANTIA (um por ação):
//   * PayEscrowUseCase       -> contratante paga (simulado);
//   * ConfirmServiceUseCase  -> cada um confirma que o serviço foi feito;
//   * OpenDisputeUseCase     -> abre disputa com o motivo.
//
// Cada um confere a regra ANTES de chamar o servidor (resposta rápida e
// mensagem clara). O banco confere de novo — nunca confiamos só no app.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

/// Parâmetros comuns: o pagamento e quem está agindo.
class EscrowActionParams extends Equatable {
  final Payment payment;
  final String userId;

  /// Usado só na disputa.
  final String reason;

  const EscrowActionParams({required this.payment, required this.userId, this.reason = ''});

  @override
  List<Object?> get props => [payment, userId, reason];
}

@injectable
class PayEscrowUseCase implements UseCase<Payment, EscrowActionParams> {
  final PaymentRepository repository;

  PayEscrowUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(EscrowActionParams params) async {
    if (!params.payment.canPay(params.userId)) {
      return const Left(ValidationFailure('Este pagamento não pode ser feito agora.'));
    }
    return repository.pay(params.payment.id);
  }
}

@injectable
class ConfirmServiceUseCase implements UseCase<Payment, EscrowActionParams> {
  final PaymentRepository repository;

  ConfirmServiceUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(EscrowActionParams params) async {
    final payment = params.payment;
    if (payment.confirmedBy(params.userId)) {
      return const Left(ValidationFailure('Você já confirmou este serviço.'));
    }
    if (!payment.canConfirm(params.userId)) {
      return const Left(
        ValidationFailure('Só é possível confirmar quando o valor está em garantia.'),
      );
    }
    return repository.confirmService(payment.id);
  }
}

@injectable
class OpenDisputeUseCase implements UseCase<Payment, EscrowActionParams> {
  final PaymentRepository repository;

  OpenDisputeUseCase(this.repository);

  static const int minReasonLength = 10;
  static const int maxReasonLength = 1000;

  @override
  Future<Either<Failure, Payment>> call(EscrowActionParams params) async {
    if (!params.payment.canDispute(params.userId)) {
      return const Left(
        ValidationFailure('Só é possível abrir disputa enquanto o valor está em garantia.'),
      );
    }
    final reason = params.reason.trim();
    if (reason.length < minReasonLength || reason.length > maxReasonLength) {
      return const Left(
        ValidationFailure('Descreva o problema com 10 a 1000 caracteres.'),
      );
    }
    return repository.openDispute(params.payment.id, reason);
  }
}
