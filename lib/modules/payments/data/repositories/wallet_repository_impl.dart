// =============================================================================
// modules/payments/data/repositories/wallet_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO da carteira usando o SUPABASE.
//
//   * Extrato: tabela `wallet_entries` em TEMPO REAL;
//   * Conta para receber: tabela `payout_accounts` (só o dono lê e grava);
//   * Saque: função do banco `request_withdrawal` (confere saldo e conta).
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/payout_account.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'payment_repository_impl.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _client;

  WalletRepositoryImpl(this._client);

  @override
  Stream<List<WalletEntry>> watchEntries(String userId) {
    return _client
        .from('wallet_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false) // mais recentes primeiro
        .map((rows) => rows.map(_entryFromJson).toList());
  }

  @override
  Future<Either<Failure, PayoutAccount?>> getPayoutAccount(String userId) {
    return guardRequest<PayoutAccount?>(() async {
      final row = await _client
          .from('payout_accounts')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // nenhuma linha -> null
      return row == null ? null : accountFromJson(row);
    });
  }

  @override
  Future<Either<Failure, Unit>> savePayoutAccount(String userId, PayoutAccount account) {
    return guardRequest<Unit>(() async {
      // upsert = insere se não existe, atualiza se já existe (chave: user_id).
      await _client.from('payout_accounts').upsert(accountToJson(userId, account));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Withdrawal>> requestWithdrawal(double amount, WithdrawalMethod method) {
    return guardRequest<Withdrawal>(() async {
      final response = await _client.rpc(
        'request_withdrawal',
        params: {'p_amount': amount, 'p_method': method.value},
      );
      final json = response as Map<String, dynamic>;
      return Withdrawal(
        id: json['id'] as String,
        amount: PaymentRepositoryImpl.parseMoney(json['amount']),
        method: json['method'] == 'ted' ? WithdrawalMethod.ted : WithdrawalMethod.pix,
        destination: json['destination'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Conversões JSON <-> entidades (públicas para os testes)
  // ---------------------------------------------------------------------------

  static WalletEntry _entryFromJson(Map<String, dynamic> json) {
    return WalletEntry(
      id: json['id'] as String,
      amount: PaymentRepositoryImpl.parseMoney(json['amount']),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  static PayoutAccount accountFromJson(Map<String, dynamic> json) {
    return PayoutAccount(
      holderName: json['holder_name'] as String,
      holderDocument: json['holder_document'] as String,
      pixKeyType: PixKeyType.fromValue(json['pix_key_type'] as String?),
      pixKey: json['pix_key'] as String?,
      bankCode: json['bank_code'] as String?,
      bankName: json['bank_name'] as String?,
      agency: json['agency'] as String?,
      accountNumber: json['account_number'] as String?,
      accountType: BankAccountType.fromValue(json['account_type'] as String?),
    );
  }

  /// Envia TODOS os campos (inclusive nulos): se o usuário removeu o Pix ou
  /// a conta bancária, o valor antigo é apagado no banco.
  static Map<String, dynamic> accountToJson(String userId, PayoutAccount account) {
    return {
      'user_id': userId,
      'holder_name': account.holderName.trim(),
      'holder_document': account.holderDocument,
      'pix_key_type': account.pixKeyType?.value,
      'pix_key': account.pixKey,
      'bank_code': account.bankCode,
      'bank_name': account.bankName,
      'agency': account.agency,
      'account_number': account.accountNumber,
      'account_type': account.accountType?.value,
    };
  }
}
