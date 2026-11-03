// =============================================================================
// modules/account/presentation/pages/account_page.dart
// -----------------------------------------------------------------------------
// TEL20 — CONTA E MODO DE USO (compartilhada pelos dois modos).
//
//   (LF) Leonardo Fontes / leo@email.com      <- toque na foto para trocar
//   MODO DE USO
//     Contratar      Buscar profissionais perto do set         (•)
//     Profissional   Gerenciar meu perfil e aparecer...        ( ) | [Ativar]
//   [Quer ser encontrado também?  Criar perfil profissional]   <- TEL20-E2
//   Dados da conta · Dados da produtora · Minha carteira ·
//   Privacidade e dados · Sair
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../onboarding/presentation/pages/recruiter_activation_page.dart';
import '../../../payments/presentation/pages/wallet_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../mode_switch.dart';
import 'account_data_page.dart';
import 'privacy_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isUploadingAvatar = false;

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Toque na foto: escolhe na galeria e envia (vale para os dois modos).
  Future<void> _changeAvatar() async {
    final session = context.read<SessionCubit>();
    final profile = session.state.profile!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    final result = await getIt<ProfileRepository>().uploadAvatar(
      userId: profile.id,
      bytes: await picked.readAsBytes(),
    );
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);
    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (url) {
        session.updateProfile(profile.copyWith(avatarUrl: url));
        showAppMessage(context, 'Foto atualizada!');
      },
    );
  }

  Future<void> _signOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sair da conta?',
      message: 'Você precisará entrar de novo com e-mail e senha.',
      confirmLabel: 'Sair',
    );
    if (confirmed && mounted) await context.read<SessionCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Conta'), actions: const [ModeIndicatorChip()]),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, session) {
          final profile = session.profile;
          if (profile == null) return const SizedBox.shrink();
          final otherIsProfessional = session.isRecruiterMode;
          final otherActive = otherIsProfessional ? profile.isProfessional : profile.isRecruiter;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            children: [
              // ---- Cabeçalho ------------------------------------------------
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Trocar foto de perfil',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isUploadingAvatar ? null : _changeAvatar,
                      child: Stack(
                        children: [
                          UserAvatar(imageUrl: profile.avatarUrl, name: profile.fullName, radius: 30),
                          if (_isUploadingAvatar)
                            const Positioned.fill(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.fullName, style: theme.textTheme.titleMedium),
                        Text(profile.email ?? '', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Modo de uso ----------------------------------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MODO DE USO', style: theme.textTheme.labelSmall),
                      _ModeRow(
                        title: 'Contratar',
                        subtitle: 'Buscar profissionais perto do set',
                        selected: session.mode == AppMode.recruiter,
                        active: profile.isRecruiter,
                        onSelect: () => switchToMode(context, AppMode.recruiter),
                      ),
                      const Divider(),
                      _ModeRow(
                        title: 'Profissional',
                        subtitle: 'Gerenciar meu perfil e aparecer nas buscas',
                        selected: session.mode == AppMode.professional,
                        active: profile.isProfessional,
                        onSelect: () => switchToMode(context, AppMode.professional),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- TEL20-E2: convite para o modo que falta ---------------------
              if (!otherActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        otherIsProfessional
                            ? 'Quer ser encontrado também?'
                            : 'Quer contratar também?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        otherIsProfessional
                            ? 'Crie seu perfil profissional na mesma conta. Você não precisa se cadastrar de novo.'
                            : 'Ative o modo Contratar na mesma conta. Você não precisa se cadastrar de novo.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: AppTheme.highlightButton,
                        onPressed: () => switchToMode(
                          context,
                          otherIsProfessional ? AppMode.professional : AppMode.recruiter,
                        ),
                        child: Text(
                          otherIsProfessional ? 'Criar perfil profissional' : 'Ativar modo Contratar',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // ---- Atalhos da conta -------------------------------------------
              _MenuTile(
                icon: Icons.person,
                title: 'Dados da conta',
                onTap: () => _open(const AccountDataPage()),
              ),
              if (profile.isRecruiter)
                _MenuTile(
                  icon: Icons.movie_creation,
                  title: 'Dados da produtora',
                  onTap: () => _open(const RecruiterActivationPage(editing: true)),
                ),
              if (profile.isProfessional)
                _MenuTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Minha carteira',
                  onTap: () => _open(const WalletPage()),
                ),
              _MenuTile(
                icon: Icons.shield,
                title: 'Privacidade e dados',
                onTap: () => _open(const PrivacyPage()),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.primary),
                title: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: _signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Linha de modo: título + descrição + seleção (ou "Ativar").
class _ModeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool active;
  final VoidCallback onSelect;

  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: active && !selected ? onSelect : null,
      selected: selected,
      trailing: active
          ? Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            )
          : OutlinedButton(onPressed: onSelect, child: const Text('Ativar')),
    );
  }
}

/// Item da lista de atalhos, com divisória embaixo.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }
}
