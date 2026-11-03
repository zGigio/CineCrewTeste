// =============================================================================
// modules/account/presentation/mode_switch.dart
// -----------------------------------------------------------------------------
// TROCA DE MODO (uma conta, dois modos — TEL20).
//
//   * O outro perfil já está ativo -> mostra a transição (TEL20-E1) e troca,
//     sem novo login (RN43);
//   * Ainda não está ativo -> abre a ativação (TEL05 ou TEL09) (TEL20-E2).
// Usado pelo indicador ⇄ do topo e pela tela Conta.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/session_cubit.dart';
import '../../auth/presentation/cubit/session_state.dart';
import '../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../onboarding/presentation/pages/recruiter_activation_page.dart';
import 'pages/switching_mode_page.dart';

Future<void> switchToMode(BuildContext context, AppMode mode) async {
  final session = context.read<SessionCubit>().state;
  final profile = session.profile;
  if (profile == null || session.mode == mode) return;

  final isActive = mode == AppMode.professional ? profile.isProfessional : profile.isRecruiter;
  final Widget page = isActive
      ? SwitchingModePage(target: mode)
      : mode == AppMode.professional
          ? const ProfessionalOnboardingPage()
          : const RecruiterActivationPage();
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
