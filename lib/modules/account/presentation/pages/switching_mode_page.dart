// =============================================================================
// modules/account/presentation/pages/switching_mode_page.dart
// -----------------------------------------------------------------------------
// TEL20-E1 — "ALTERNANDO PARA O MODO ..." (transição curta).
//
// Mostra por um instante que a troca está acontecendo e que a sessão e os
// dados da conta continuam os mesmos; depois troca o modo e fecha.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';

class SwitchingModePage extends StatefulWidget {
  final AppMode target;

  const SwitchingModePage({super.key, required this.target});

  /// Duração da transição (curta: só o suficiente para ser percebida).
  static const Duration duration = Duration(milliseconds: 700);

  @override
  State<SwitchingModePage> createState() => _SwitchingModePageState();
}

class _SwitchingModePageState extends State<SwitchingModePage> {
  @override
  void initState() {
    super.initState();
    _switch();
  }

  Future<void> _switch() async {
    final session = context.read<SessionCubit>();
    await Future<void>.delayed(SwitchingModePage.duration);
    if (!mounted) return;
    session.switchMode(widget.target);
    // Volta para a raiz: a tela principal já está no modo novo.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Alternando para o modo ${widget.target.label}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua sessão e os dados da conta continuam os mesmos.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
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
