// =============================================================================
// test/modules/payments/payments_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 7: garantia (pagamento simulado), carteira e saques.
//   * regras do Payment (quem pode pagar, confirmar, disputar);
//   * casos de uso com um repositório FALSO (sem internet);
//   * validação de CPF, CNPJ, chave Pix, agência e conta;
//   * saldo da carteira e conversão do JSON do banco.
// Rodar com: flutter test
// =============================================================================

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/payments/data/repositories/payment_repository_impl.dart';
import 'package:audiovisual_app/modules/payments/domain/entities/payment.dart';
import 'package:audiovisual_app/modules/payments/domain/entities/payout_account.dart';
import 'package:audiovisual_app/modules/payments/domain/entities/wallet.dart';
import 'package:audiovisual_app/modules/payments/domain/payout_validators.dart';
import 'package:audiovisual_app/modules/payments/domain/repositories/payment_repository.dart';
import 'package:audiovisual_app/modules/payments/domain/repositories/wallet_repository.dart';
import 'package:audiovisual_app/modules/payments/domain/usecases/escrow_usecases.dart';
import 'package:audiovisual_app/modules/payments/domain/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Right, Unit, unit;

const recruiter = 'contratante-1';
const professional = 'profissional-1';
const stranger = 'outra-pessoa';

Payment buildPayment({
  PaymentStatus status = PaymentStatus.awaitingPayment,
  bool payerConfirmed = false,
  bool payeeConfirmed = false,
}) {
  return Payment(
    id: 'pag-1',
    applicationId: 'cand-1',
    payerId: recruiter,
    payeeId: professional,
    amount: 1500,
    status: status,
    payerConfirmed: payerConfirmed,
    payeeConfirmed: payeeConfirmed,
    createdAt: DateTime(2026, 10, 17),
  );
}

/// Repositório FALSO: registra o que foi chamado e devolve o pagamento.
class FakePaymentRepository implements PaymentRepository {
  final calls = <String>[];

  @override
  Stream<Payment?> watchByApplication(String applicationId) => const Stream.empty();

  @override
  Future<Either<Failure, Payment>> pay(String paymentId) async {
    calls.add('pay');
    return Right(buildPayment(status: PaymentStatus.held));
  }

  @override
  Future<Either<Failure, Payment>> confirmService(String paymentId) async {
    calls.add('confirm');
    return Right(buildPayment(status: PaymentStatus.held, payerConfirmed: true));
  }

  @override
  Future<Either<Failure, Payment>> openDispute(String paymentId, String reason) async {
    calls.add('dispute');
    return Right(buildPayment(status: PaymentStatus.disputed));
  }
}

class FakeWalletRepository implements WalletRepository {
  double? withdrawnAmount;
  PayoutAccount? saved;

  @override
  Stream<List<WalletEntry>> watchEntries(String userId) => const Stream.empty();

  @override
  Future<Either<Failure, PayoutAccount?>> getPayoutAccount(String userId) async =>
      Right(saved);

  @override
  Future<Either<Failure, Unit>> savePayoutAccount(String userId, PayoutAccount account) async {
    saved = account;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Withdrawal>> requestWithdrawal(
    double amount,
    WithdrawalMethod method,
  ) async {
    withdrawnAmount = amount;
    return Right(
      Withdrawal(
        id: 'saque-1',
        amount: amount,
        method: method,
        destination: 'Pix · email ••••.com',
        status: 'concluido',
        createdAt: DateTime(2026, 10, 17),
      ),
    );
  }
}

const pixAccount = PayoutAccount(
  holderName: 'Fabio Filmaker',
  holderDocument: '52998224725',
  pixKeyType: PixKeyType.email,
  pixKey: 'fabio@email.com',
);

void main() {
  group('Regras do pagamento', () {
    test('só o contratante paga, e só enquanto aguarda pagamento', () {
      final payment = buildPayment();
      expect(payment.canPay(recruiter), isTrue);
      expect(payment.canPay(professional), isFalse);
      expect(buildPayment(status: PaymentStatus.held).canPay(recruiter), isFalse);
    });

    test('os dois confirmam uma vez cada enquanto está em garantia', () {
      final held = buildPayment(status: PaymentStatus.held, payerConfirmed: true);
      expect(held.canConfirm(recruiter), isFalse); // já confirmou
      expect(held.canConfirm(professional), isTrue);
      expect(held.canConfirm(stranger), isFalse);
      expect(buildPayment().canConfirm(professional), isFalse); // ainda não pago
    });

    test('etapas da linha do tempo', () {
      expect(buildPayment().step, 0);
      expect(buildPayment(status: PaymentStatus.held).step, 1);
      expect(buildPayment(status: PaymentStatus.disputed).step, 1);
      expect(buildPayment(status: PaymentStatus.released).step, 2);
    });
  });

  group('Casos de uso da garantia', () {
    late FakePaymentRepository repository;

    setUp(() => repository = FakePaymentRepository());

    test('profissional não consegue pagar (nem chega ao servidor)', () async {
      final result = await PayEscrowUseCase(repository)(
        EscrowActionParams(payment: buildPayment(), userId: professional),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('contratante paga e o valor fica em garantia', () async {
      final result = await PayEscrowUseCase(repository)(
        EscrowActionParams(payment: buildPayment(), userId: recruiter),
      );
      expect(result.getOrElse((_) => throw StateError('falhou')).status, PaymentStatus.held);
      expect(repository.calls, ['pay']);
    });

    test('confirmar duas vezes é bloqueado', () async {
      final result = await ConfirmServiceUseCase(repository)(
        EscrowActionParams(
          payment: buildPayment(status: PaymentStatus.held, payerConfirmed: true),
          userId: recruiter,
        ),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('disputa exige um motivo com pelo menos 10 caracteres', () async {
      final useCase = OpenDisputeUseCase(repository);
      final held = buildPayment(status: PaymentStatus.held);

      final short = await useCase(
        EscrowActionParams(payment: held, userId: professional, reason: 'ruim'),
      );
      expect(short.isLeft(), isTrue);

      final ok = await useCase(
        EscrowActionParams(
          payment: held,
          userId: professional,
          reason: 'O contratante não apareceu no set.',
        ),
      );
      expect(ok.isRight(), isTrue);
      expect(repository.calls, ['dispute']);
    });
  });

  group('Validação dos dados bancários', () {
    test('CPF e CNPJ conferem os dígitos verificadores', () {
      expect(PayoutValidators.isValidCpf('529.982.247-25'), isTrue);
      expect(PayoutValidators.isValidCpf('529.982.247-24'), isFalse);
      expect(PayoutValidators.isValidCpf('111.111.111-11'), isFalse);
      expect(PayoutValidators.isValidCnpj('11.222.333/0001-81'), isTrue);
      expect(PayoutValidators.isValidCnpj('11.222.333/0001-82'), isFalse);
    });

    test('chave Pix de acordo com o tipo', () {
      expect(PayoutValidators.pixKey(PixKeyType.email, 'leo@email.com'), isNull);
      expect(PayoutValidators.pixKey(PixKeyType.email, 'leo@'), isNotNull);
      expect(PayoutValidators.pixKey(PixKeyType.phone, '(21) 99999-8888'), isNull);
      expect(PayoutValidators.pixKey(PixKeyType.phone, '9999'), isNotNull);
      expect(
        PayoutValidators.pixKey(PixKeyType.random, '123e4567-e89b-12d3-a456-426614174000'),
        isNull,
      );
    });

    test('telefone Pix é salvo no padrão +55', () {
      expect(
        PayoutValidators.normalizePixKey(PixKeyType.phone, '(21) 99999-8888'),
        '+5521999998888',
      );
      expect(PayoutValidators.normalizePixKey(PixKeyType.cpf, '529.982.247-25'), '52998224725');
    });

    test('agência e conta', () {
      expect(PayoutValidators.agency('0001'), isNull);
      expect(PayoutValidators.agency('0001-2'), isNotNull);
      expect(PayoutValidators.accountNumber('12345-6'), isNull);
      expect(PayoutValidators.accountNumber('abc'), isNotNull);
    });

    test('conta sem Pix e sem banco é recusada', () async {
      final result = await SavePayoutAccountUseCase(FakeWalletRepository())(
        const SavePayoutAccountParams(
          userId: professional,
          account: PayoutAccount(holderName: 'Fabio', holderDocument: '52998224725'),
        ),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('Carteira e saque', () {
    test('saldo = soma do extrato, sem erro de arredondamento', () {
      final entries = [
        WalletEntry(id: '1', amount: 0.1, description: 'a', createdAt: DateTime(2026)),
        WalletEntry(id: '2', amount: 0.2, description: 'b', createdAt: DateTime(2026)),
        WalletEntry(id: '3', amount: -0.3, description: 'c', createdAt: DateTime(2026)),
      ];
      expect(walletBalance(entries), 0);
    });

    test('saque maior que o saldo é bloqueado', () async {
      final repository = FakeWalletRepository();
      final result = await RequestWithdrawalUseCase(repository)(
        const WithdrawalParams(
          amount: 2000,
          method: WithdrawalMethod.pix,
          balance: 1500,
          account: pixAccount,
        ),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.withdrawnAmount, isNull);
    });

    test('TED sem conta bancária cadastrada é bloqueado', () async {
      final result = await RequestWithdrawalUseCase(FakeWalletRepository())(
        const WithdrawalParams(
          amount: 100,
          method: WithdrawalMethod.ted,
          balance: 1500,
          account: pixAccount,
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('saque válido via Pix', () async {
      final repository = FakeWalletRepository();
      final result = await RequestWithdrawalUseCase(repository)(
        const WithdrawalParams(
          amount: 1500,
          method: WithdrawalMethod.pix,
          balance: 1500,
          account: pixAccount,
        ),
      );
      expect(result.isRight(), isTrue);
      expect(repository.withdrawnAmount, 1500);
    });
  });

  group('Conversão do JSON do banco', () {
    test('valor em dinheiro aceita número ou texto (tempo real)', () {
      final payment = PaymentRepositoryImpl.paymentFromJson({
        'id': 'pag-1',
        'application_id': 'cand-1',
        'payer_id': recruiter,
        'payee_id': professional,
        'amount': '1500.50',
        'status': 'retido',
        'payer_confirmed': true,
        'payee_confirmed': false,
        'created_at': '2026-10-17T12:00:00Z',
        'paid_at': '2026-10-17T13:00:00Z',
      });
      expect(payment.amount, 1500.5);
      expect(payment.status, PaymentStatus.held);
      expect(payment.paidAt, isNotNull);
      expect(payment.releasedAt, isNull);
    });
  });
}
