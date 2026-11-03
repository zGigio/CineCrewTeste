// =============================================================================
// core/config/env.dart
// -----------------------------------------------------------------------------
// VARIÁVEIS DE AMBIENTE do aplicativo.
//
// Dados de conexão NÃO ficam escritos no código-fonte (que vai para o GitHub).
// Eles são passados na hora de rodar o app, a partir de um arquivo env.json
// (que está no .gitignore, ou seja, nunca é enviado ao repositório):
//
//   flutter run --dart-define-from-file=env.json
//
// Modelo do arquivo: env.example.json (na raiz do projeto).
// =============================================================================

/// Acesso centralizado às configurações de ambiente.
///
/// O construtor privado `Env._()` impede que alguém crie objetos desta
/// classe: ela serve apenas para agrupar constantes.
class Env {
  Env._();

  /// URL do projeto Supabase (ex.: https://abcdefgh.supabase.co).
  /// `String.fromEnvironment` lê o valor passado via --dart-define.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Chave PÚBLICA (anon key) do Supabase. Ela pode ficar no app porque o
  /// acesso aos dados é protegido pelas regras de RLS do banco.
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Indica se as duas configurações obrigatórias foram informadas.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
