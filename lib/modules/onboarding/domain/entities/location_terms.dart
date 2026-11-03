// =============================================================================
// modules/onboarding/domain/entities/location_terms.dart
// -----------------------------------------------------------------------------
// TEXTO E VERSÃO DO TERMO DE USO DA LOCALIZAÇÃO (TEL07 / RF28).
//
// A versão é gravada junto com o aceite: se o texto mudar no futuro, sabemos
// exatamente o que cada pessoa aceitou. O texto e a base legal ainda serão
// revisados juridicamente (pendência P03 da documentação).
// =============================================================================

class LocationTerms {
  LocationTerms._();

  /// Versão do texto. Mude sempre que o texto abaixo mudar.
  static const String version = 'v1-2026-10';

  /// Os três pontos explicados na tela, como nas pranchas.
  static const List<String> points = [
    'Permitir que contratantes encontrem você por proximidade e especialidade.',
    'Contratantes veem só uma posição aproximada, nunca o seu endereço.',
    'Você pode revogar o aceite quando quiser, em Privacidade e dados.',
  ];

  static const String checkboxText =
      'Li e concordo com o tratamento da minha localização para esta finalidade.';
}
