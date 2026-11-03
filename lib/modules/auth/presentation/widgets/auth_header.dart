// =============================================================================
// modules/auth/presentation/widgets/auth_header.dart
// -----------------------------------------------------------------------------
// TÍTULO das telas de acesso ("Entrar", "Crie sua conta"), no padrão
// "título de tela" do design system (22/28 negrito), com texto de apoio
// opcional embaixo.
// =============================================================================

import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header: true -> o leitor de tela anuncia como título.
        Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
