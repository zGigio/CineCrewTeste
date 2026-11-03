// =============================================================================
// modules/auth/presentation/pages/auth_gate.dart
// -----------------------------------------------------------------------------
// "PORTEIRO" do app: decide a primeira tela conforme a sessão.
//
//   verificando sessão ............ carregamento
//   ninguém logado ................ Boas-vindas (TEL01)
//   logado, conta sem perfil ...... Como você quer começar? (TEL04)
//   logado, com perfil ativo ...... tela principal (Home)
//   logado, conta desativada ...... aviso + "Reativar conta" (TEL02-E2)
//   logado, perfil não carregou .... erro + "Tentar de novo" / "Sair"
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';
import '../../../account/presentation/pages/reactivate_account_page.dart';
import 'choose_mode_page.dart';
import 'session_error_page.dart';
import 'welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      // Só redesenha quando muda o STATUS ou quando a conta ganha o primeiro
      // perfil (e não a cada edição de perfil).
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          (previous.profile?.hasAnyRole ?? false) != (current.profile?.hasAnyRole ?? false),
      builder: (context, state) {
        // "switch expression": escolhe um widget para cada situação.
        return switch (state.status) {
          SessionStatus.unknown => const _LoadingView(),
          SessionStatus.unauthenticated => const WelcomePage(),
          SessionStatus.deactivated => const ReactivateAccountPage(),
          SessionStatus.loadError => SessionErrorPage(message: state.errorMessage),
          SessionStatus.authenticated when !(state.profile?.hasAnyRole ?? false) =>
            const ChooseModePage(),
          SessionStatus.authenticated => const HomePage(),
        };
      },
    );
  }
}

/// Tela de carregamento enquanto a sessão é verificada.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
