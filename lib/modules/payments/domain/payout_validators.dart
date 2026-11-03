// =============================================================================
// modules/payments/domain/payout_validators.dart
// -----------------------------------------------------------------------------
// VALIDAÇÕES DOS DADOS BANCÁRIOS (Dart puro, sem Flutter, fácil de testar).
//
//   * CPF e CNPJ: confere os DÍGITOS VERIFICADORES (os 2 últimos números são
//     calculados a partir dos outros — assim um número digitado errado é
//     recusado antes de ir para o banco de dados);
//   * Chave Pix: formato de acordo com o tipo;
//   * Agência e conta: só números (a conta pode ter dígito: "12345-6").
//
// Cada função devolve a MENSAGEM DE ERRO, ou `null` se estiver tudo certo
// (mesmo padrão dos validadores dos formulários do Flutter).
// =============================================================================

import 'entities/payout_account.dart';

class PayoutValidators {
  PayoutValidators._(); // só funções estáticas

  /// Mantém apenas os dígitos: "529.982.247-25" -> "52998224725".
  static String onlyDigits(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');

  /// CPF válido? (11 dígitos + dígitos verificadores corretos)
  static bool isValidCpf(String input) {
    final cpf = onlyDigits(input);
    if (cpf.length != 11) return false;
    // "111.111.111-11" passa na conta, mas não é um CPF de verdade.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    final digits = cpf.split('').map(int.parse).toList();
    // Dígito 1: pesos de 10 a 2 nos 9 primeiros números.
    // Dígito 2: pesos de 11 a 2 nos 10 primeiros números.
    for (final length in [9, 10]) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += digits[i] * (length + 1 - i);
      }
      final check = (sum * 10) % 11 % 10; // resto 10 vira 0
      if (check != digits[length]) return false;
    }
    return true;
  }

  /// CNPJ válido? (14 dígitos + dígitos verificadores corretos)
  static bool isValidCnpj(String input) {
    final cnpj = onlyDigits(input);
    if (cnpj.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;

    final digits = cnpj.split('').map(int.parse).toList();
    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (final weights in [weights1, weights2]) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += digits[i] * weights[i];
      }
      final rest = sum % 11;
      final check = rest < 2 ? 0 : 11 - rest;
      if (check != digits[weights.length]) return false;
    }
    return true;
  }

  static String? holderName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 3) return 'Informe o nome completo do titular.';
    if (name.length > 120) return 'Nome muito longo.';
    return null;
  }

  static String? document(String? value) {
    final digits = onlyDigits(value ?? '');
    if (digits.length == 11) return isValidCpf(digits) ? null : 'CPF inválido.';
    if (digits.length == 14) return isValidCnpj(digits) ? null : 'CNPJ inválido.';
    return 'Informe um CPF (11 números) ou CNPJ (14 números).';
  }

  /// Valida a chave Pix conforme o tipo escolhido.
  static String? pixKey(PixKeyType type, String? value) {
    final key = value?.trim() ?? '';
    if (key.isEmpty) return 'Informe a chave Pix.';
    switch (type) {
      case PixKeyType.cpf:
        return isValidCpf(key) ? null : 'CPF inválido.';
      case PixKeyType.cnpj:
        return isValidCnpj(key) ? null : 'CNPJ inválido.';
      case PixKeyType.email:
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(key) && key.length <= 77
            ? null
            : 'E-mail inválido.';
      case PixKeyType.phone:
        final digits = onlyDigits(key);
        // Com DDD: 10 ou 11 dígitos (ou 12/13 já com o 55 do Brasil).
        final national = digits.startsWith('55') && digits.length > 11
            ? digits.substring(2)
            : digits;
        return national.length == 10 || national.length == 11
            ? null
            : 'Telefone inválido: use DDD + número.';
      case PixKeyType.random:
        // Chave aleatória = UUID com 36 caracteres (32 letras/números + 4 hífens).
        return RegExp(r'^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$').hasMatch(key)
            ? null
            : 'Chave aleatória inválida (formato: 8-4-4-4-12 caracteres).';
    }
  }

  /// Deixa a chave Pix no formato padrão antes de salvar:
  /// CPF/CNPJ só com números, telefone como "+5521999998888", e-mail minúsculo.
  static String normalizePixKey(PixKeyType type, String value) {
    final key = value.trim();
    switch (type) {
      case PixKeyType.cpf:
      case PixKeyType.cnpj:
        return onlyDigits(key);
      case PixKeyType.email:
      case PixKeyType.random:
        return key.toLowerCase();
      case PixKeyType.phone:
        final digits = onlyDigits(key);
        return digits.startsWith('55') && digits.length > 11 ? '+$digits' : '+55$digits';
    }
  }

  static String? agency(String? value) {
    final agency = value?.trim() ?? '';
    return RegExp(r'^[0-9]{1,5}$').hasMatch(agency)
        ? null
        : 'Agência: até 5 números, sem dígito.';
  }

  static String? accountNumber(String? value) {
    final account = value?.trim() ?? '';
    return RegExp(r'^[0-9]{1,13}(-[0-9Xx])?$').hasMatch(account)
        ? null
        : 'Conta: números com o dígito após o hífen (ex.: 12345-6).';
  }

  /// Confere a conta inteira (usado pelo caso de uso antes de salvar).
  static String? account(PayoutAccount account) {
    final errors = [
      holderName(account.holderName),
      document(account.holderDocument),
      if (account.pixKeyType != null) pixKey(account.pixKeyType!, account.pixKey),
      if (account.bankCode != null) ...[
        agency(account.agency),
        accountNumber(account.accountNumber),
        if (account.accountType == null) 'Escolha o tipo da conta.',
      ],
    ];
    final firstError = errors.whereType<String>().firstOrNull;
    if (firstError != null) return firstError;
    if (!account.hasPix && !account.hasBankAccount) {
      return 'Cadastre uma chave Pix ou uma conta bancária.';
    }
    return null;
  }
}
