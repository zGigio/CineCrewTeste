// =============================================================================
// core/di/register_module.dart
// -----------------------------------------------------------------------------
// MÓDULO DE REGISTRO de dependências EXTERNAS.
//
// Classes que nós escrevemos recebem @injectable direto nelas. Mas classes de
// pacotes de terceiros (como o `SupabaseClient`) não podem ser anotadas, pois
// não somos donos do código delas. Para essas, criamos um @module: uma classe
// que "ensina" o GetIt a obter esses objetos.
// =============================================================================

import 'package:injectable/injectable.dart';

// Supabase: back-end pronto (PostgreSQL + PostGIS, login, arquivos e tempo
// real). O `show` importa apenas o que este arquivo usa.
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, SupabaseClient;

/// `@module` indica ao injectable que esta classe fornece dependências.
/// É abstrata porque o gerador cria uma subclasse concreta automaticamente.
@module
abstract class RegisterModule {
  /// Cliente do Supabase usado por todos os repositórios.
  ///
  /// `@lazySingleton`: uma única instância no app inteiro, criada só quando
  /// alguém pedir pela primeira vez. O `Supabase.initialize` (no main.dart)
  /// precisa ter rodado ANTES — por isso ele é chamado antes da injeção.
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
