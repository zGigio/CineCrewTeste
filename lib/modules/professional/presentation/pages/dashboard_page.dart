// =============================================================================
// modules/professional/presentation/pages/dashboard_page.dart
// -----------------------------------------------------------------------------
// TEL16 — PAINEL DO PROFISSIONAL (primeira aba do modo Profissional).
//
//   Olá, Leonardo / Veja como está o seu perfil.
//   [cartão de visibilidade com a lista de verificação]
//   Disponível para novos trabalhos  (interruptor)
//   [✎ Editar perfil]  [🔗 Portfólio]
//
// Extras do app (fora da documentação), embaixo: atalhos para candidaturas
// e carteira, categorias de vagas e "Vagas perto de você".
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_icons.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../applications/presentation/pages/my_applications_page.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../home/presentation/widgets/category_carousel.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../home/presentation/widgets/nearby_jobs_section.dart';
import '../../../jobs/presentation/pages/job_search_page.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../../payments/presentation/pages/wallet_page.dart';
import '../../../portfolio/domain/repositories/portfolio_repository.dart';
import '../../../portfolio/presentation/pages/manage_portfolio_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../widgets/visibility_status_card.dart';
import 'edit_professional_page.dart';

class DashboardPage extends StatefulWidget {
  /// Abre a aba Perfil (usado pelo "Definir localização" das vagas perto).
  final VoidCallback onOpenProfile;

  const DashboardPage({super.key, required this.onOpenProfile});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? _portfolioCount;
  bool _isSavingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadPortfolioCount();
  }

  Future<void> _loadPortfolioCount() async {
    final userId = context.read<SessionCubit>().state.profile!.id;
    final result = await getIt<PortfolioRepository>().getItems(userId);
    if (!mounted) return;
    setState(() => _portfolioCount = result.fold((_) => 0, (items) => items.length));
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// "Disponível para novos trabalhos" (salva na hora).
  Future<void> _setAvailability(bool value) async {
    final session = context.read<SessionCubit>();
    setState(() => _isSavingAvailability = true);
    final result = await getIt<ProfileRepository>().updateProfile(
      session.state.profile!.copyWith(isAvailable: value),
    );
    if (!mounted) return;
    setState(() => _isSavingAvailability = false);
    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      session.updateProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel'),
        actions: const [NotificationBell(), ModeIndicatorChip()],
      ),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, session) {
          final profile = session.profile;
          if (profile == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: _loadPortfolioCount,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              children: [
                Text(
                  'Olá, ${profile.firstName}',
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
                Text('Veja como está o seu perfil.', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                VisibilityStatusCard(profile: profile, portfolioCount: _portfolioCount),
                if (!profile.isVisibleInSearch) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: AppTheme.highlightButton,
                    onPressed: () => _open(const ProfessionalOnboardingPage()),
                    icon: const Icon(Icons.place),
                    label: const Text('Concluir perfil profissional'),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Disponível para novos trabalhos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Desligado, você some do filtro "Somente disponíveis".'),
                    value: profile.isAvailable,
                    onChanged: _isSavingAvailability ? null : _setAvailability,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _open(const EditProfessionalPage()),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ManagePortfolioPage()),
                          );
                          _loadPortfolioCount(); // pode ter mudado
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Portfólio'),
                      ),
                    ),
                  ],
                ),

                // ---- Extras do app ----------------------------------------------
                const SizedBox(height: 24),
                Text('ATALHOS', style: theme.textTheme.labelSmall),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.assignment, color: AppColors.primary),
                        title: const Text('Minhas candidaturas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(const MyApplicationsPage()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        title: const Text('Minha carteira'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(const WalletPage()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Vagas por categoria', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                CategoryCarousel(
                  onSelected: (RoleCategory category) => _open(
                    JobSearchPage(initialRole: category.role, autoSearch: true),
                  ),
                ),
                const SizedBox(height: 24),
                NearbyJobsSection(profile: profile, onSetLocation: widget.onOpenProfile),
              ],
            ),
          );
        },
      ),
    );
  }
}
