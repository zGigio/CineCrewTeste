// =============================================================================
// modules/payments/domain/entities/payout_account.dart
// -----------------------------------------------------------------------------
// ENTIDADE: CONTA PARA RECEBER (para onde vão os saques da carteira).
//
// O profissional pode cadastrar:
//   * uma CHAVE PIX (CPF, CNPJ, e-mail, telefone ou chave aleatória); e/ou
//   * uma CONTA BANCÁRIA para TED (banco, agência, conta e tipo).
// O titular (nome + CPF/CNPJ) é obrigatório.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Tipos de chave Pix definidos pelo Banco Central.
enum PixKeyType {
  cpf('cpf', 'CPF'),
  cnpj('cnpj', 'CNPJ'),
  email('email', 'E-mail'),
  phone('telefone', 'Telefone'),
  random('aleatoria', 'Chave aleatória');

  final String value;
  final String label;

  const PixKeyType(this.value, this.label);

  static PixKeyType? fromValue(String? value) =>
      PixKeyType.values.where((type) => type.value == value).firstOrNull;
}

/// Tipo da conta bancária.
enum BankAccountType {
  checking('corrente', 'Conta corrente'),
  savings('poupanca', 'Poupança');

  final String value;
  final String label;

  const BankAccountType(this.value, this.label);

  static BankAccountType? fromValue(String? value) =>
      BankAccountType.values.where((type) => type.value == value).firstOrNull;
}

class PayoutAccount extends Equatable {
  final String holderName;

  /// CPF (11 dígitos) ou CNPJ (14 dígitos), SOMENTE números.
  final String holderDocument;

  // ---- Pix ----
  final PixKeyType? pixKeyType;
  final String? pixKey;

  // ---- TED ----
  /// Código do banco com 3 dígitos (ex.: "341" = Itaú).
  final String? bankCode;
  final String? bankName;
  final String? agency;
  final String? accountNumber;
  final BankAccountType? accountType;

  const PayoutAccount({
    required this.holderName,
    required this.holderDocument,
    this.pixKeyType,
    this.pixKey,
    this.bankCode,
    this.bankName,
    this.agency,
    this.accountNumber,
    this.accountType,
  });

  bool get hasPix => pixKey != null && pixKeyType != null;
  bool get hasBankAccount =>
      bankCode != null && agency != null && accountNumber != null && accountType != null;

  /// CPF/CNPJ mascarado para exibir na tela: "•••.982.247-••".
  String get maskedDocument {
    final d = holderDocument;
    if (d.length == 11) return '•••.${d.substring(3, 6)}.${d.substring(6, 9)}-••';
    if (d.length == 14) return '••.${d.substring(2, 5)}.${d.substring(5, 8)}/••••-••';
    return d;
  }

  /// Resumo do Pix: "Pix (E-mail) ••••.com".
  String? get pixSummary => hasPix ? 'Pix (${pixKeyType!.label}) ••••${_lastFour(pixKey!)}' : null;

  /// Resumo da conta: "Banco 341 · Ag. 0001 · Conta ••••45-6".
  String? get bankSummary => hasBankAccount
      ? '${bankName ?? 'Banco $bankCode'} · Ag. $agency · Conta ••••${_lastFour(accountNumber!)}'
      : null;

  static String _lastFour(String text) =>
      text.length <= 4 ? text : text.substring(text.length - 4);

  @override
  List<Object?> get props => [
        holderName, holderDocument, pixKeyType, pixKey,
        bankCode, bankName, agency, accountNumber, accountType,
      ];
}
