// =============================================================================
// test/core/formatters_test.dart
// -----------------------------------------------------------------------------
// TESTES UNITÁRIOS das formatações (reais, datas e distâncias).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:audiovisual_app/core/utils/formatters.dart';

void main() {
  group('Formatters.currency', () {
    test('formata com separador de milhar e centavos', () {
      expect(Formatters.currency(1500), 'R\$ 1.500,00');
      expect(Formatters.currency(1234567.5), 'R\$ 1.234.567,50');
      expect(Formatters.currency(80), 'R\$ 80,00');
    });
  });

  group('Formatters.parseCurrency', () {
    test('lê os formatos brasileiro e internacional', () {
      expect(Formatters.parseCurrency('1.500,50'), 1500.5);
      expect(Formatters.parseCurrency('1500,50'), 1500.5);
      expect(Formatters.parseCurrency('1500.50'), 1500.5);
      expect(Formatters.parseCurrency('R\$ 300'), 300);
    });

    test('devolve null para texto inválido', () {
      expect(Formatters.parseCurrency(''), isNull);
      expect(Formatters.parseCurrency('abc'), isNull);
    });
  });

  group('Formatters.distance', () {
    test('usa metros abaixo de 1 km e km com vírgula acima', () {
      expect(Formatters.distance(0.35), '350 m');
      expect(Formatters.distance(7.18), '7,2 km');
    });
  });

  group('Formatters.period', () {
    test('mesmo dia mostra a data uma vez só', () {
      final start = DateTime(2026, 3, 7, 8);
      final end = DateTime(2026, 3, 7, 18);
      expect(Formatters.period(start, end), '07/03/2026, 08:00 às 18:00');
    });

    test('dias diferentes mostram início e fim', () {
      final start = DateTime(2026, 3, 7, 8);
      final end = DateTime(2026, 3, 9, 18);
      expect(Formatters.period(start, end), '07/03 08:00 até 09/03 18:00');
    });
  });
}
