// =============================================================================
// test/core/validators_test.dart
// -----------------------------------------------------------------------------
// TESTES UNITÁRIOS das validações de formulário.
//
// Teste unitário = testa uma função isolada, comparando o resultado obtido
// com o resultado esperado (`expect(obtido, esperado)`).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:audiovisual_app/core/utils/validators.dart';

void main() {
  // `group` agrupa testes relacionados no relatório.
  group('Validators.email', () {
    test('aceita e-mail válido', () {
      expect(Validators.email('leo@uva.br'), isNull);
    });

    test('recusa e-mail vazio', () {
      expect(Validators.email('   '), 'Informe seu e-mail.');
    });

    test('recusa e-mail sem @ ou sem domínio', () {
      expect(Validators.email('leo.uva.br'), 'E-mail inválido.');
      expect(Validators.email('leo@uva'), 'E-mail inválido.');
    });
  });

  group('Validators.password', () {
    test('recusa senha curta', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('aceita senha com o tamanho mínimo', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.requiredField', () {
    test('recusa texto só com espaços', () {
      expect(
        Validators.requiredField('   ', fieldName: 'O nome'),
        'O nome é obrigatório.',
      );
    });

    test('aceita texto preenchido', () {
      expect(Validators.requiredField('Ana'), isNull);
    });
  });

  group('Validators.newPassword (cadastro)', () {
    test('recusa senha curta ou sem número', () {
      expect(Validators.newPassword('abc123'), isNotNull); // só 6 caracteres
      expect(Validators.newPassword('abcdefgh'), isNotNull); // sem número
      expect(Validators.newPassword('12345678'), isNotNull); // sem letra
    });

    test('aceita 8+ caracteres com letras e números', () {
      expect(Validators.newPassword('cinecrew26'), isNull);
    });
  });
}
