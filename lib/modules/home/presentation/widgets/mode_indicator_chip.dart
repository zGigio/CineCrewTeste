// =============================================================================
// modules/home/presentation/widgets/mode_indicator_chip.dart
// -----------------------------------------------------------------------------
// INDICADOR DE MODO na barra superior (design system, seção 6):
//
//   [⇄ Contratar]     (azul-marinho)  — modo Contratar
//   [⇄ Profissional]  (âmbar)         — modo Profissional
//
// Cor nunca é a única pista: o texto diz o modo. Tocar alterna para o outro
// modo (se o perfil dele já estiver ativo) ou abre a ativação do perfil
// que falta — sem novo login (RN43).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../account/presentation/mode_switch.dart';

class ModeIndicatorChip extends StatelessWidget {
  const ModeIndicatorChip({super.key});

  /// Toca: vai para o OUTRO modo (com a transição TEL20-E1) ou abre a
  /// ativação do perfil que ainda falta (TEL20-E2).
  void _onTap(BuildContext context, SessionState session) {
    switchToMode(
      context,
      session.isRecruiterMode ? AppMode.professional : AppMode.recruiter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      buildWhen: (previous, current) => previous.mode != current.mode,
      builder: (context, session) {
        if (session.profile == null) return const SizedBox.shrink();
        final isRecruiter = session.isRecruiterMode;
        final background = isRecruiter ? AppColors.primary : AppColors.accent;
        final foreground = isRecruiter ? Colors.white : AppColors.text;
        final label = isRecruiter ? 'Contratar' : 'Profissional';

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Semantics(
            button: true,
            label: 'Modo atual: $label. Toque para trocar de modo.',
            excludeSemantics: true,
            child: Material(
              color: background,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => _onTap(context, session),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 18, color: foreground),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
