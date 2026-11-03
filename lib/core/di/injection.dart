// =============================================================================
// core/di/injection.dart
// -----------------------------------------------------------------------------
// INJEÇÃO DE DEPENDÊNCIAS (DI - Dependency Injection).
//
// Ideia: uma classe não deve criar sozinha as classes de que depende.
// Ex.: o Repositório precisa de um DataSource; em vez de fazer
// `TalentRemoteDataSourceImpl(...)` dentro dele, ele RECEBE o DataSource
// pronto no construtor. Quem monta e entrega essas peças é o GetIt.
//
// Vantagens: código desacoplado, fácil de testar (trocamos implementações
// reais por "falsas" nos testes) e fácil de manter.
//
// O pacote `injectable` lê as anotações (@injectable, @LazySingleton...)
// e GERA AUTOMATICAMENTE o arquivo `injection.config.dart`.
// Sempre que criar/alterar uma classe anotada, rode no terminal:
//
//   dart run build_runner build --delete-conflicting-outputs
// =============================================================================

// GetIt: "Service Locator" — um registro central de objetos do app.
import 'package:get_it/get_it.dart';

// Anotações usadas para gerar o código de registro automaticamente.
import 'package:injectable/injectable.dart';

// Arquivo GERADO pelo build_runner (não deve ser editado à mão).
import 'injection.config.dart';

/// Instância global e única do GetIt, acessível em todo o app.
/// Exemplo de uso: `final useCase = getIt<SearchTalentsByRadiusUseCase>();`
final GetIt getIt = GetIt.instance;

/// Registra todas as dependências do projeto no GetIt.
///
/// A anotação `@InjectableInit` avisa o gerador de código que esta é a
/// função de inicialização:
///   - `preferRelativeImports`: o arquivo gerado usa imports relativos;
///   - `asExtension`: gera o método `init()` como extensão do GetIt
///     (por isso chamamos `getIt.init()`).
///
/// A função é `Future` para que, no futuro, possamos registrar
/// dependências assíncronas (ex.: banco de dados local) com `@preResolve`.
@InjectableInit(
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();
}
