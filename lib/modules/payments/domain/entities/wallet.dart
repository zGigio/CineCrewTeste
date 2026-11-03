// =============================================================================
// modules/payments/domain/entities/wallet.dart
// -----------------------------------------------------------------------------
// ENTIDADES DA CARTEIRA:
//   * WalletEntry: uma linha do EXTRATO (entrada + ou saída -);
//   * Withdrawal:  um SAQUE pedido (via Pix ou TED);
//   * WithdrawalMethod: as duas formas de saque.
// O SALDO é a soma das linhas do extrato.
// =============================================================================

import 'package:equatable/equatable.dart';

class WalletEntry extends Equatable {
  final String id;

  /// Positivo = entrada (pagamento recebido) | negativo = saída (saque).
  final double amount;
  final String description;
  final DateTime createdAt;

  const WalletEntry({
    required this.id,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  bool get isCredit => amount > 0;

  @override
  List<Object?> get props => [id, amount, description, createdAt];
}

/// Soma do extrato = saldo disponível (arredondado em centavos).
double walletBalance(List<WalletEntry> entries) {
  final cents = entries.fold<int>(0, (sum, entry) => sum + (entry.amount * 100).round());
  return cents / 100;
}

enum WithdrawalMethod {
  pix('pix', 'Pix', 'Na hora'),
  ted('ted', 'TED', 'Em dias úteis');

  final String value;
  final String label;

  /// Prazo exibido na tela (como nos bancos reais).
  final String deadline;

  const WithdrawalMethod(this.value, this.label, this.deadline);
}

class Withdrawal extends Equatable {
  final String id;
  final double amount;
  final WithdrawalMethod method;

  /// Destino já mascarado pelo banco de dados.
  final String destination;
  final String status;
  final DateTime createdAt;

  const Withdrawal({
    required this.id,
    required this.amount,
    required this.method,
    required this.destination,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, amount, method, destination, status, createdAt];
}
