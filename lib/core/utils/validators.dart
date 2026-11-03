// =============================================================================
// core/utils/validators.dart
// -----------------------------------------------------------------------------
// VALIDAÇÕES de formulário reutilizáveis.
//
// No Flutter, cada campo de formulário (TextFormField) pode receber um
// `validator`: uma função que recebe o texto digitado e devolve:
//   - null          -> o valor é válido;
//   - uma String    -> a mensagem de erro exibida embaixo do campo.
// =============================================================================

/// Conjunto de validações usadas nos formulários do app.
class Validators {
  Validators._();

  /// Expressão regular (padrão de texto) de um e-mail simples:
  /// "algo" + "@" + "algo" + "." + "algo", sem espaços.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Tamanho mínimo da senha (o mesmo configurado no Supabase).
  static const int minPasswordLength = 6;

  /// Campo obrigatório: não pode ficar vazio nem só com espaços.
  static String? requiredField(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório.';
    }
    return null;
  }

  /// E-mail: obrigatório e no formato correto.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!_emailPattern.hasMatch(text)) return 'E-mail inválido.';
    return null;
  }

  /// Tamanho mínimo da senha NOVA (cadastro e troca de senha).
  static const int minNewPasswordLength = 8;

  /// Senha NOVA (cadastro): pelo menos 8 caracteres, com letra e número.
  /// Decisão para a pendência P07 da documentação (padrão de senha).
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Crie uma senha.';
    if (value.length < minNewPasswordLength ||
        !RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use 8 ou mais caracteres, com letras e números.';
    }
    return null;
  }

  /// Senha no LOGIN: obrigatória e com o tamanho mínimo do Supabase.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha.';
    if (value.length < minPasswordLength) {
      return 'A senha deve ter pelo menos $minPasswordLength caracteres.';
    }
    return null;
  }
}
