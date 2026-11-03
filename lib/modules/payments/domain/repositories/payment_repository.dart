// =============================================================================
// modules/payments/domain/repositories/payment_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do pagamento em garantia. A implementação (Supabase) chama as
// funções seguras do banco: pay_escrow, confirm_service e open_payment_dispute.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either;

import '../../../../core/error/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  /// Pagamento da candidatura em TEMPO REAL (`null` = ainda não existe).
  Stream<Payment?> watchByApplication(String applicationId);

  /// Contratante paga (simulado): o valor fica em garantia.
  Future<Either<Failure, Payment>> pay(String paymentId);

  /// Confirma que o serviço foi realizado.
  Future<Either<Failure, Payment>> confirmService(String paymentId);

  /// Abre uma disputa com o motivo informado.
  Future<Either<Failure, Payment>> openDispute(String paymentId, String reason);
}
