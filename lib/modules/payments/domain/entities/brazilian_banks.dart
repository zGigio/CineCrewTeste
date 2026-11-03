// =============================================================================
// modules/payments/domain/entities/brazilian_banks.dart
// -----------------------------------------------------------------------------
// LISTA REDUZIDA DE BANCOS (código COMPE de 3 dígitos + nome), usada na
// escolha do banco para TED. A lista completa tem centenas de instituições;
// aqui ficam as mais usadas, suficientes para a demonstração do TCC.
// =============================================================================

class BrazilianBank {
  final String code;
  final String name;

  const BrazilianBank(this.code, this.name);

  /// Texto do seletor: "341 - Itaú Unibanco".
  String get display => '$code - $name';
}

const List<BrazilianBank> brazilianBanks = [
  BrazilianBank('001', 'Banco do Brasil'),
  BrazilianBank('033', 'Santander'),
  BrazilianBank('077', 'Banco Inter'),
  BrazilianBank('104', 'Caixa Econômica Federal'),
  BrazilianBank('212', 'Banco Original'),
  BrazilianBank('237', 'Bradesco'),
  BrazilianBank('260', 'Nubank'),
  BrazilianBank('290', 'PagBank'),
  BrazilianBank('323', 'Mercado Pago'),
  BrazilianBank('336', 'C6 Bank'),
  BrazilianBank('341', 'Itaú Unibanco'),
  BrazilianBank('380', 'PicPay'),
  BrazilianBank('748', 'Sicredi'),
  BrazilianBank('756', 'Sicoob'),
];

/// Procura o banco pelo código (ou `null`).
BrazilianBank? bankByCode(String? code) =>
    brazilianBanks.where((bank) => bank.code == code).firstOrNull;
