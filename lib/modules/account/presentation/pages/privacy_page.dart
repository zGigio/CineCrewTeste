// =============================================================================
// modules/account/presentation/pages/privacy_page.dart
// -----------------------------------------------------------------------------
// TEL22 — PRIVACIDADE E DADOS (LGPD).
//
//   [📍 Uso da localização]   Aceite registrado em 12/09/2026 ...
//                             (Revogar aceite)  -> TEL22-E2
//   [Desativar conta]         some das buscas; só entra para reativar
//   [Excluir conta e dados]   (Excluir conta)   -> TEL22-E1
//
// O cartão de localização só aparece para quem tem perfil profissional.
// Desativar e excluir valem para a conta inteira (pendência P18).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../domain/repositories/account_repository.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isBusy = false;

  AccountRepository get _account => getIt<AccountRepository>();

  /// Executa uma ação com indicador de carregamento; devolve se deu certo.
  Future<bool> _run(Future<Either<Failure, Unit>> Function() action) async {
    setState(() => _isBusy = true);
    final result = await action();
    if (!mounted) return false;
    setState(() => _isBusy = false);
    return result.fold<bool>(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return false;
      },
      (_) => true,
    );
  }

  // ---- TEL22-E2: revogar o aceite ---------------------------------------------
  Future<void> _revoke() async {
    final session = context.read<SessionCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revogar o aceite?'),
        content: const Text(
          'Seu perfil profissional deixará de aparecer nas buscas. '
          'Para voltar, será necessário um novo aceite.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revogar aceite'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (await _run(_account.revokeLocationConsent)) {
      await session.refreshProfile(); // o perfil volta sem o aceite
      if (mounted) showAppMessage(context, 'Aceite revogado. Seu perfil saiu das buscas.');
    }
  }

  // ---- Desativar --------------------------------------------------------------
  Future<void> _deactivate() async {
    final session = context.read<SessionCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Desativar conta?',
      message: 'Você deixa de aparecer nas buscas e a sessão é encerrada. '
          'Para voltar, é só entrar e tocar em "Reativar conta".',
      confirmLabel: 'Desativar',
    );
    if (!confirmed || !mounted) return;
    if (await _run(_account.deactivateAccount)) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      await session.signOut(); // volta para a tela inicial (TEL01)
    }
  }

  // ---- TEL22-E1: excluir ------------------------------------------------------
  Future<void> _delete() async {
    final session = context.read<SessionCubit>();
    final userId = session.state.profile!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    if (await _run(() => _account.deleteAccount(userId))) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      showAppMessage(context, 'Conta e dados excluídos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e dados')),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, session) {
          final profile = session.profile;
          if (profile == null) return const SizedBox.shrink();
          final consentAt = profile.locationConsentAt;

          return AbsorbPointer(
            absorbing: _isBusy,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              children: [
                if (_isBusy) const LinearProgressIndicator(),

                // ---- Uso da localização (só perfil profissional) -------------
                if (profile.isProfessional)
                  _PrivacyCard(
                    icon: Icons.place,
                    title: 'Uso da localização',
                    text: consentAt != null
                        ? 'Aceite registrado em ${Formatters.date(consentAt)}. '
                            'Seu perfil profissional aparece nas buscas.'
                        : 'Sem aceite em vigor: seu perfil profissional não aparece nas buscas.',
                    action: consentAt != null
                        ? OutlinedButton(onPressed: _revoke, child: const Text('Revogar aceite'))
                        : OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProfessionalOnboardingPage(),
                              ),
                            ),
                            child: const Text('Aceitar novamente'),
                          ),
                  ),

                // ---- Desativar --------------------------------------------------
                _PrivacyCard(
                  title: 'Desativar conta',
                  text: 'Vale para a conta inteira. Você deixa de aparecer nas buscas '
                      'e não poderá usar o app até reativar.',
                  action: OutlinedButton(
                    onPressed: _deactivate,
                    child: const Text('Desativar conta'),
                  ),
                ),

                // ---- Excluir ------------------------------------------------------
                _PrivacyCard(
                  title: 'Excluir conta e dados',
                  titleColor: AppColors.error,
                  text: 'Remove os dados pessoais da conta, incluindo a localização, '
                      'fotos, currículo, portfólio e mensagens.',
                  action: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    onPressed: _delete,
                    child: const Text('Excluir conta'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seus dados são tratados conforme a LGPD. O texto e a base legal do '
                  'termo ainda serão validados juridicamente.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Color? titleColor;
  final String text;
  final Widget action;

  const _PrivacyCard({
    this.icon,
    required this.title,
    this.titleColor,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: titleColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }
}

/// TEL22-E1: confirmação da exclusão, com caixa "Entendo que é definitiva".
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir conta?', style: TextStyle(color: AppColors.error)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seus dados pessoais, incluindo a localização, serão removidos. '
            'Esta ação não pode ser desfeita.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: const Text('Entendo que a exclusão é definitiva.'),
          ),
        ],
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        FilledButton(
          style: AppTheme.destructiveButton,
          // Exclusão exige ciência e confirmação explícita.
          onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Excluir definitivamente'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
