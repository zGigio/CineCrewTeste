// =============================================================================
// modules/onboarding/domain/onboarding_validators.dart
// -----------------------------------------------------------------------------
// VALIDAÇÕES da ativação dos perfis (Dart puro, fácil de testar).
// Cada função devolve a mensagem de erro, ou `null` se estiver tudo certo.
// =============================================================================

import '../../../core/constants/audiovisual_roles.dart';

class OnboardingValidators {
  OnboardingValidators._();

  /// Nome profissional / nome do responsável: 2 a 80 caracteres.
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Informe o nome.';
    if (text.length > 80) return 'Nome muito longo (máx. 80).';
    return null;
  }

  /// Canal de contato: telefone/WhatsApp com DDD (10 ou 11 números).
  static String? contact(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe um telefone para contato.';
    if (digits.length < 10 || digits.length > 11) {
      return 'Use DDD + número, ex.: (21) 99999-8888.';
    }
    return null;
  }

  /// Especialidades: pelo menos uma, só do catálogo, sem repetição (RN09/RN10).
  static String? specialties(List<String> values) {
    if (values.isEmpty) return 'Selecione ao menos uma especialidade.';
    if (values.toSet().length != values.length) return 'Especialidade repetida.';
    final unknown = values.where((value) => !audiovisualRoles.contains(value));
    if (unknown.isNotEmpty) return 'Especialidade fora do catálogo: ${unknown.first}.';
    return null;
  }

  /// Produtora / empresa: 2 a 120 caracteres.
  static String? company(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Informe o nome da produtora.';
    if (text.length > 120) return 'Nome muito longo (máx. 120).';
    return null;
  }
}
