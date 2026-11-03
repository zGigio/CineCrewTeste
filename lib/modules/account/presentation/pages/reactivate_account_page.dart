// =============================================================================
// modules/account/presentation/pages/reactivate_account_page.dart
// -----------------------------------------------------------------------------
// TEL02-E2 — CONTA DESATIVADA.
//
// Decisão para a pendência P01 (opção "a"): a pessoa consegue entrar só
// para ver este aviso e, se quiser, REATIVAR a conta. Nada mais do app
// fica acessível enquanto a conta estiver desativada.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/widgets/auth_header.dart';
import '../../domain/repositories/account_repository.dart';

class ReactivateAccountPage extends StatefulWidget {
  const ReactivateAccountPage({super.key});

  @override
  State<ReactivateAccountPage> createState() => _ReactivateAccountPageState();
}

class _ReactivateAccountPageState extends State<ReactivateAccountPage> {
  bool _isBusy = false;

  Future<void> _reactivate() async {
    final session = context.read<SessionCubit>();
    setState(() => _isBusy = true);
    final result = await getIt<AccountRepository>().reactivateAccount();
    if (!mounted) return;
    setState(() => _isBusy = false);
    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      // Recarrega o perfil: o AuthGate passa a mostrar o app.
      (_) => session.refreshProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<SessionCubit>().state.profile?.email ?? '';
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          children: [
            const AuthHeader(title: 'Entrar'),
            const SizedBox(height: 16),
            const AppBanner.warning('Esta conta está desativada e não pode iniciar sessão.'),
            const SizedBox(height: 16),
            if (email.isNotEmpty)
              Text('Conta: $email', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Ao reativar, seu perfil volta a aparecer nas buscas (se o aceite '
              'de uso da localização estiver em vigor).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _isBusy ? null : _reactivate,
              child: _isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reativar conta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isBusy ? null : () => context.read<SessionCubit>().signOut(),
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}
