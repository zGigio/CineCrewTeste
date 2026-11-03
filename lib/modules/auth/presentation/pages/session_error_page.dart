// =============================================================================
// modules/auth/presentation/pages/session_error_page.dart
// -----------------------------------------------------------------------------
// ERRO AO CARREGAR A SESSÃO.
//
// A pessoa entrou (o Supabase aceitou e-mail e senha), mas o PERFIL dela não
// pôde ser carregado do banco. Antes o app voltava em silêncio para a tela de
// boas-vindas e parecia que o login "não entrava". Agora mostra o motivo e
// oferece "Tentar de novo" e "Sair".
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_banner.dart';
import '../cubit/session_cubit.dart';
import '../widgets/auth_header.dart';

class SessionErrorPage extends StatelessWidget {
  /// Motivo da falha (já traduzido pelo `guardRequest`).
  final String? message;

  const SessionErrorPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>();
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          children: [
            const AuthHeader(title: 'Não foi possível abrir sua conta'),
            const SizedBox(height: 16),
            AppBanner.error(message ?? 'Erro ao carregar o seu perfil.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.retry,
              child: const Text('Tentar de novo'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: session.signOut,
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}
