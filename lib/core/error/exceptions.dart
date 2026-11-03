// =============================================================================
// core/error/exceptions.dart
// -----------------------------------------------------------------------------
// EXCEÇÕES da camada de DADOS (data).
//
// Na Clean Architecture separamos dois conceitos:
//   - Exception (este arquivo): é LANÇADA (throw) pela camada de dados quando
//     algo dá errado (ex.: servidor fora do ar). Interrompe a execução.
//   - Failure (failures.dart): é RETORNADA como valor pelo repositório,
//     dentro de um Either. A interface trata o erro sem try/catch.
//
// O repositório é quem "traduz" Exception -> Failure.
// =============================================================================

/// Exceção lançada pelo DataSource remoto quando a comunicação com a API
/// (back-end) falha ou devolve dados em formato inesperado.
class ServerException implements Exception {
  /// Mensagem legível que poderá ser exibida ao usuário.
  final String message;

  /// Código HTTP devolvido pelo servidor (ex.: 404, 500).
  /// Pode ser nulo quando nem houve resposta (ex.: sem internet).
  final int? statusCode;

  /// Construtor com valores padrão para a mensagem.
  const ServerException({
    this.message = 'Erro de conexão com o servidor.',
    this.statusCode,
  });

  /// Representação textual da exceção (útil em logs e depuração).
  @override
  String toString() => 'ServerException($statusCode): $message';
}
