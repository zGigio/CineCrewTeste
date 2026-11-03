// =============================================================================
// core/error/failures.dart
// -----------------------------------------------------------------------------
// FALHAS (Failures) do aplicativo.
//
// Uma Failure é um erro tratado como VALOR. Em vez de "explodir" uma exceção,
// os repositórios devolvem `Either<Failure, Sucesso>` (pacote fpdart):
//   - Left(Failure)  -> deu errado;
//   - Right(valor)   -> deu certo.
// Assim a interface é OBRIGADA a tratar os dois casos, deixando o app mais
// seguro e previsível.
// =============================================================================

// Equatable: permite comparar objetos pelo VALOR dos campos, e não pela
// posição na memória. Muito útil em testes (expect(falha, ServerFailure())).
import 'package:equatable/equatable.dart';

/// Classe base ABSTRATA de todas as falhas do aplicativo.
/// "Abstrata" significa que não pode ser instanciada diretamente,
/// apenas suas filhas (ServerFailure, LocationFailure...).
abstract class Failure extends Equatable {
  /// Mensagem amigável que descreve o erro para o usuário.
  final String message;

  const Failure(this.message);

  /// Lista de campos usados pelo Equatable para comparar duas falhas.
  @override
  List<Object?> get props => [message];
}

/// Falha na comunicação com a API / servidor (back-end).
class ServerFailure extends Failure {
  /// Código HTTP retornado (ex.: 404 = não encontrado, 500 = erro interno).
  final int? statusCode;

  const ServerFailure({
    String message = 'Ocorreu um erro no servidor. Tente novamente mais tarde.',
    this.statusCode,
  }) : super(message);

  /// Inclui o statusCode na comparação de igualdade.
  @override
  List<Object?> get props => [message, statusCode];
}

/// Falha de autenticação: login, cadastro ou sessão expirada.
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Não foi possível autenticar. Tente novamente.',
  ]);
}

/// Falha relacionada ao GPS do dispositivo (serviço desligado ou
/// permissão de localização negada).
class LocationFailure extends Failure {
  /// Os colchetes `[ ]` indicam parâmetro OPCIONAL posicional,
  /// com uma mensagem padrão caso nenhuma seja informada.
  const LocationFailure([
    super.message = 'Não foi possível obter a localização do dispositivo.',
  ]);
}

/// Falha de validação: dados de entrada inválidos ou regra de negócio violada
/// (ex.: raio de busca negativo).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Falha genérica para qualquer erro inesperado que não se encaixe
/// nas categorias acima.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Ocorreu um erro inesperado. Tente novamente.',
  ]);
}
