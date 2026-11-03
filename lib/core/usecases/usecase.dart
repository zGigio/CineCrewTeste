// =============================================================================
// core/usecases/usecase.dart
// -----------------------------------------------------------------------------
// CONTRATO BASE dos Casos de Uso (Use Cases).
//
// Na Clean Architecture, um Caso de Uso representa UMA ação de negócio que o
// usuário pode realizar (ex.: "buscar talentos num raio de X km").
// Todos os casos de uso seguem o mesmo formato, definido aqui.
// =============================================================================

import 'package:equatable/equatable.dart';

// fpdart: biblioteca de programação funcional. Usamos o tipo `Either`.
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Contrato que todo Caso de Uso deve implementar.
///
/// É uma classe GENÉRICA com dois tipos:
///   - [SuccessType]: o que é devolvido em caso de sucesso
///     (ex.: `List<ProfessionalEntity>`);
///   - [Params]: os parâmetros de entrada (ex.: `SearchParams`).
///
/// O método se chama `call`, o que permite executar o caso de uso como se
/// fosse uma função: `await searchTalents(params);`
abstract class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// Usado quando um Caso de Uso NÃO precisa de parâmetros de entrada.
/// Exemplo: `await getMyProfile(const NoParams());`
class NoParams extends Equatable {
  const NoParams();

  /// Sem campos: duas instâncias de NoParams são sempre iguais.
  @override
  List<Object?> get props => [];
}
