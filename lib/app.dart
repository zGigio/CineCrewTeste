// =============================================================================
// app.dart
// -----------------------------------------------------------------------------
// WIDGET RAIZ do aplicativo.
//
// Define as configurações globais:
//   - tema visual "cinema escuro" (fundo escuro + destaque âmbar);
//   - idioma português do Brasil (calendários, botões "Cancelar"/"OK");
//   - o SessionCubit disponível para TODAS as telas;
//   - a primeira tela: o AuthGate (decide entre login e home).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/presentation/cubit/session_cubit.dart';
import 'modules/auth/presentation/pages/auth_gate.dart';

class AudiovisualApp extends StatelessWidget {
  const AudiovisualApp({super.key});

  /// Título exibido pelo sistema operacional (lista de apps recentes).
  static const String appTitle = 'CineCrew';

  @override
  Widget build(BuildContext context) {
    // BlocProvider.value "pendura" o SessionCubit no topo da árvore de
    // widgets: qualquer tela abaixo consegue acessá-lo com
    // `context.read<SessionCubit>()` ou `context.watch<SessionCubit>()`.
    return BlocProvider<SessionCubit>.value(
      value: getIt<SessionCubit>(),
      child: MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        // Tema claro do design system CineCrew (documentação, seção 3).
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,

        // Traduções oficiais do Flutter para os componentes prontos.
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),

        home: const AuthGate(),
      ),
    );
  }
}
