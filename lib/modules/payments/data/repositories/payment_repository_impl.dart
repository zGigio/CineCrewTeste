// =============================================================================
// modules/payments/data/repositories/payment_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO da garantia usando o SUPABASE.
//
//   * Leitura: tabela `payments` em TEMPO REAL (`.stream`) — quando o outro
//     lado paga ou confirma, a tela atualiza sozinha;
//   * Ações: funções do banco via RPC (pay_escrow, confirm_service,
//     open_payment_dispute). O app NÃO pode alterar a tabela diretamente.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

@LazySingleton(as: PaymentRepository)
class PaymentRepositoryImpl implements PaymentRepository {
  final SupabaseClient _client;

  PaymentRepositoryImpl(this._client);

  @override
  Stream<Payment?> watchByApplication(String applicationId) {
    return _client
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('application_id', applicationId)
        .map((rows) => rows.isEmpty ? null : paymentFromJson(rows.first));
  }

  @override
  Future<Either<Failure, Payment>> pay(String paymentId) =>
      _callAction('pay_escrow', {'p_payment_id': paymentId});

  @override
  Future<Either<Failure, Payment>> confirmService(String paymentId) =>
      _callAction('confirm_service', {'p_payment_id': paymentId});

  @override
  Future<Either<Failure, Payment>> openDispute(String paymentId, String reason) =>
      _callAction('open_payment_dispute', {'p_payment_id': paymentId, 'p_reason': reason});

  /// Chama a função do banco e converte o pagamento devolvido.
  Future<Either<Failure, Payment>> _callAction(String function, Map<String, dynamic> params) {
    return guardRequest<Payment>(() async {
      final response = await _client.rpc(function, params: params);
      return paymentFromJson(response as Map<String, dynamic>);
    });
  }

  /// JSON (linha da tabela) -> entidade. Público para ser usado nos testes.
  static Payment paymentFromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      amount: parseMoney(json['amount']),
      status: PaymentStatus.fromValue(json['status'] as String?),
      payerConfirmed: (json['payer_confirmed'] as bool?) ?? false,
      payeeConfirmed: (json['payee_confirmed'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      paidAt: _parseDate(json['paid_at']),
      releasedAt: _parseDate(json['released_at']),
      disputeReason: json['dispute_reason'] as String?,
    );
  }

  /// Valores em dinheiro (numeric) podem chegar como número ou como texto
  /// (o tempo real às vezes envia "1500.50").
  static double parseMoney(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}
