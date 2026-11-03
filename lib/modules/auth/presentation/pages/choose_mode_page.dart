// =============================================================================
// modules/auth/presentation/pages/choose_mode_page.dart
// -----------------------------------------------------------------------------
// TEL04 — COMO VOCÊ QUER COMEÇAR?
//
// Aparece logo depois de criar a conta (conta ainda sem perfil). A pessoa
// escolhe o PRIMEIRO modo; o outro pode ser ativado depois, na mesma conta,
// sem novo cadastro nem novo login.
//
//   [ilustração]  Quero contratar        >
//   [ilustração]  Quero ser encontrado   >
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/set_illustration.dart';
import '../../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../../onboarding/presentation/pages/recruiter_activation_page.dart';
import '../cubit/session_cubit.dart';
import '../widgets/auth_header.dart';

class ChooseModePage extends StatelessWidget {
  const ChooseModePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.read<SessionCubit>().signOut(),
            child: const Text('Sair'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          children: [
            const AuthHeader(
              title: 'Como você quer começar?',
              subtitle: 'Você poderá usar os dois modos com a mesma conta, '
                  'sem novo cadastro ou novo login.',
            ),
            const SizedBox(height: 20),
            _ModeCard(
              palette: SetPalette.navy,
              title: 'Quero contratar',
              description: 'Encontre profissionais perto do set de filmagem.',
              // TEL09: dados da produtora.
              onTap: () => _open(context, const RecruiterActivationPage()),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              palette: SetPalette.teal,
              title: 'Quero ser encontrado',
              description: 'Crie seu perfil profissional e apareça nas buscas por proximidade.',
              // TEL05 a TEL08: perfil profissional em 4 passos.
              onTap: () => _open(context, const ProfessionalOnboardingPage()),
            ),
            const SizedBox(height: 24),
            Text(
              'Dica: o outro modo pode ser ativado depois, na tela de Perfil.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de escolha: miniatura ilustrada + título + descrição + seta.
class _ModeCard extends StatelessWidget {
  final SetPalette palette;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModeCard({
    required this.palette,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 56, height: 56, child: SetIllustration(palette: palette)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
