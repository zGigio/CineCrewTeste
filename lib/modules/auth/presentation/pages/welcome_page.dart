// =============================================================================
// modules/auth/presentation/pages/welcome_page.dart
// -----------------------------------------------------------------------------
// TEL01 — BOAS-VINDAS (primeira tela para quem não está logado).
//
//   [ ilustração do set + ícone de câmera ]
//   A equipe certa, perto do set.
//   Encontre profissionais do audiovisual por especialidade e proximidade...
//   [ Criar conta ]   <- destaque (âmbar)
//   [   Entrar    ]   <- secundário (contorno)
//   Uma conta, dois modos de uso: contratar e ser encontrado.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/set_illustration.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Em telas largas (tablet) o conteúdo não fica esticado.
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ilustração ocupa o espaço que sobrar no topo.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const SetIllustration(),
                          Positioned(
                            left: 14,
                            top: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.videocam, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'A equipe certa, perto do set.',
                      style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Encontre profissionais do audiovisual por especialidade e '
                    'proximidade, ou apareça para quem procura.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    style: AppTheme.highlightButton,
                    onPressed: () => _open(context, const SignUpPage()),
                    child: const Text('Criar conta'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _open(context, const LoginPage()),
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Uma conta, dois modos de uso: contratar e ser encontrado.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
