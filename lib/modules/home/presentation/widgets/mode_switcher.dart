// =============================================================================
// modules/home/presentation/widgets/mode_switcher.dart
// -----------------------------------------------------------------------------
// SELETOR DE MODO: Profissional <-> Contratante.
//
// Inspirado no "Mudar para modo anfitrião" do Airbnb. Só aparece para quem
// tem os DOIS papéis. O modo escolhido define quais abas o app mostra
// (nas próximas partes: buscar vagas x publicar vagas).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';

class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    // `context.watch`: redesenha este widget quando a sessão muda.
    final session = context.watch<SessionCubit>().state;

    // SegmentedButton: botões lado a lado em que só um fica selecionado.
    return SegmentedButton<AppMode>(
      segments: const [
        ButtonSegment(
          value: AppMode.professional,
          label: Text('Profissional'),
          icon: Icon(Icons.videocam_outlined),
        ),
        ButtonSegment(
          value: AppMode.recruiter,
          label: Text('Contratante'),
          icon: Icon(Icons.business_center_outlined),
        ),
      ],
      selected: {session.mode},
      onSelectionChanged: (selection) =>
          context.read<SessionCubit>().switchMode(selection.first),
    );
  }
}
