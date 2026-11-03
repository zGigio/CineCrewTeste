// =============================================================================
// main.dart
// -----------------------------------------------------------------------------
// PONTO DE ENTRADA do aplicativo CineCrew ("Banco de Talentos Geolocalizado
// para a Indústria Audiovisual").
//
// Todo aplicativo Flutter começa pela função `main()`. É aqui que:
//   1. Preparamos o motor do Flutter (binding);
//   2. Conectamos ao back-end (Supabase);
//   3. Registramos as dependências do sistema (injeção de dependências);
//   4. Mandamos o Flutter desenhar o primeiro widget na tela (runApp).
//
// O widget raiz (tema, idioma e primeira tela) fica no arquivo app.dart.
// =============================================================================

// Biblioteca de componentes visuais do Material Design (Google).
import 'package:flutter/material.dart';

// SDK do Supabase para Flutter (só a classe usada aqui).
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app.dart';
import 'core/config/env.dart';
import 'core/config/missing_config_app.dart';

// Arquivo que configura o Service Locator (GetIt) com todas as classes
// do projeto (repositórios, casos de uso, serviços...).
import 'core/di/injection.dart';

/// Função principal: é a primeira coisa executada quando o app abre.
///
/// É marcada como `async` porque precisa ESPERAR (await) a conexão com o
/// Supabase e a configuração das dependências antes de desenhar a interface.
Future<void> main() async {
  // Garante que o "binding" (a ponte entre o código Dart e o motor nativo do
  // Flutter no Android) esteja inicializado ANTES de qualquer outra coisa.
  // Sem isso, plugins nativos chamados antes do runApp falhariam.
  WidgetsFlutterBinding.ensureInitialized();

  // Se o app foi iniciado sem o env.json, mostra uma tela explicando
  // como configurar, em vez de travar com erro.
  if (!Env.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  // Conecta ao projeto Supabase (banco, login, arquivos e tempo real).
  // Também restaura automaticamente a sessão do usuário que já fez login.
  // `publishableKey` é o nome novo do antigo `anonKey`: aceita tanto a
  // chave "anon public" (legada) quanto a "publishable key" do painel.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Inicializa o Service Locator: registra no GetIt todas as classes anotadas
  // com @injectable / @LazySingleton.
  await configureDependencies();

  // Manda o Flutter "inflar" o widget raiz e exibi-lo na tela.
  runApp(const AudiovisualApp());
}
