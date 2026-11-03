// =============================================================================
// core/config/missing_config_app.dart
// -----------------------------------------------------------------------------
// Tela exibida quando o app é aberto SEM as configurações do Supabase.
// Em vez de "travar" com um erro técnico, explica como resolver.
// =============================================================================

import 'package:flutter/material.dart';

/// Aplicativo mínimo de aviso de configuração ausente.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.settings_suggest_outlined, size: 48),
                SizedBox(height: 16),
                Text(
                  'Configuração do Supabase não encontrada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Copie o arquivo env.example.json para env.json\n'
                  '2. Preencha SUPABASE_URL e SUPABASE_ANON_KEY\n'
                  '3. Rode: flutter run --dart-define-from-file=env.json',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
