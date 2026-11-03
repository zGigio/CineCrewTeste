// =============================================================================
// modules/payments/domain/entities/payment.dart
// -----------------------------------------------------------------------------
// ENTIDADE: PAGAMENTO EM GARANTIA (simulado, inspirado na Garantia OLX).
//
//   aguardando pagamento ──► em garantia 🔒 ──► liberado ✅
//                                 └──► em disputa ⚠️
//
// O contratante paga e o valor fica GUARDADO na plataforma. Só quando os
// DOIS confirmam que o serviço foi feito, o valor vai para a carteira do
// profissional. Nenhum dinheiro real é movimentado.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Situação do pagamento. `value` é o texto gravado no banco.
enum PaymentStatus {
  awaitingPayment('aguardando_pagamento', 'Aguardando pagamento'),
  held('retido', 'Em garantia'),
  released('liberado', 'Liberado'),
  refunded('reembolsado', 'Reembolsado'),
  disputed('em_disputa', 'Em disputa');

  final String value;
  final String label;

  const PaymentStatus(this.value, this.label);

  /// Converte o texto do banco no enum (desconhecido -> aguardando).
  static PaymentStatus fromValue(String? value) => PaymentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => PaymentStatus.awaitingPayment,
      );
}

class Payment extends Equatable {
  final String id;
  final String applicationId;

  /// Quem paga (contratante) e quem recebe (profissional).
  final String payerId;
  final String payeeId;

  final double amount;
  final PaymentStatus status;

  /// Cada lado confirma que o serviço foi realizado.
  final bool payerConfirmed;
  final bool payeeConfirmed;

  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? releasedAt;
  final String? disputeReason;

  const Payment({
    required this.id,
    required this.applicationId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    required this.status,
    required this.payerConfirmed,
    required this.payeeConfirmed,
    required this.createdAt,
    this.paidAt,
    this.releasedAt,
    this.disputeReason,
  });

  bool isPayer(String userId) => userId == payerId;
  bool isPayee(String userId) => userId == payeeId;
  bool isParticipant(String userId) => isPayer(userId) || isPayee(userId);

  /// O usuário já confirmou o serviço?
  bool confirmedBy(String userId) =>
      (isPayer(userId) && payerConfirmed) || (isPayee(userId) && payeeConfirmed);

  // ---- O que cada um pode fazer agora (as mesmas regras do banco) ----------

  /// Só o contratante paga, e só enquanto aguarda pagamento.
  bool canPay(String userId) =>
      isPayer(userId) && status == PaymentStatus.awaitingPayment;

  /// Os dois confirmam (uma vez cada) enquanto o valor está em garantia.
  bool canConfirm(String userId) =>
      isParticipant(userId) && status == PaymentStatus.held && !confirmedBy(userId);

  /// Qualquer um dos dois pode abrir disputa enquanto está em garantia.
  bool canDispute(String userId) =>
      isParticipant(userId) && status == PaymentStatus.held;

  /// Etapa na linha do tempo: 0 = pagar, 1 = em garantia, 2 = liberado.
  int get step => switch (status) {
        PaymentStatus.awaitingPayment => 0,
        PaymentStatus.released => 2,
        _ => 1,
      };

  @override
  List<Object?> get props => [
        id, applicationId, payerId, payeeId, amount, status,
        payerConfirmed, payeeConfirmed, createdAt, paidAt, releasedAt, disputeReason,
      ];
}
