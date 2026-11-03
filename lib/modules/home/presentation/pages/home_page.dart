// =============================================================================
// modules/home/presentation/pages/home_page.dart
// -----------------------------------------------------------------------------
// TELA PRINCIPAL (depois do login), com barra de navegação inferior.
//
// As abas mudam conforme o MODO de uso (como no Airbnb, que tem abas
// diferentes para hóspede e anfitrião):
//   - Modo Profissional: Painel | Perfil | Vagas | Mensagens | Conta
//   - Modo Contratar:    Explorar | Projetos | Vagas | Mensagens | Conta
//     (Painel, Perfil, Explorar, Projetos e Conta = TEL16, TEL17, TEL10,
//      TEL15 e TEL20 da documentação; Vagas e Mensagens são extras do app).
//
// A tela também cria o NotificationsCubit, que alimenta o sino 🔔.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../chat/presentation/pages/conversations_page.dart';
import '../../../jobs/presentation/pages/job_search_page.dart';
import '../../../jobs/presentation/pages/recruiter_jobs_page.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../explore/presentation/cubit/projects_cubit.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../explore/presentation/pages/projects_page.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../professional/presentation/pages/dashboard_page.dart';
import '../../../professional/presentation/pages/my_professional_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Índice da aba selecionada (0 = Início; a última é sempre o Perfil).
  int _currentIndex = 0;

  /// Cubit das notificações: criado uma vez e escutando em tempo real.
  late final NotificationsCubit _notificationsCubit;

  /// Projetos do modo Contratar: compartilhado por Explorar (recentes) e
  /// Projetos (TEL15). Criado só quando é usado pela primeira vez.
  late final ProjectsCubit _projectsCubit = getIt<ProjectsCubit>()..load();
  bool _projectsCreated = false;

  @override
  void initState() {
    super.initState();
    final userId = context.read<SessionCubit>().state.profile!.id;
    _notificationsCubit = getIt<NotificationsCubit>()..watch(userId);
  }

  @override
  void dispose() {
    _notificationsCubit.close(); // para de escutar o tempo real
    if (_projectsCreated) _projectsCubit.close();
    super.dispose();
  }

  /// Muda a cada vaga publicada pelo atalho do Início. Usado como `key` da
  /// aba "Minhas vagas": uma key nova recria a aba, que recarrega a lista.
  int _recruiterJobsVersion = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  /// Vaga publicada pelo atalho: recarrega "Vagas" e vai até ela.
  void _onJobCreated() => setState(() {
        _recruiterJobsVersion++;
        _currentIndex = 2;
      });

  /// Abas do modo CONTRATAR (TEL10 Explorar, TEL15 Projetos) + extras.
  List<Widget> _recruiterPages() => [
        ExplorePage(onJobCreated: _onJobCreated),
        const ProjectsPage(),
        RecruiterJobsPage(key: ValueKey(_recruiterJobsVersion)),
        const ConversationsPage(),
        const AccountPage(),
      ];

  static const _recruiterDestinations = [
    NavigationDestination(
      icon: Icon(Icons.search),
      selectedIcon: Icon(Icons.search),
      label: 'Explorar',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projetos',
    ),
    NavigationDestination(
      icon: Icon(Icons.work_outline),
      selectedIcon: Icon(Icons.work),
      label: 'Vagas',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Mensagens',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: 'Conta',
    ),
  ];

  /// Abas do modo PROFISSIONAL (TEL16 Painel, TEL17 Perfil, TEL20 Conta) +
  /// extras (Vagas e Mensagens). As candidaturas ficam em Vagas e no Painel.
  List<Widget> _professionalPages() => [
        DashboardPage(onOpenProfile: () => _goToTab(1)),
        const MyProfessionalProfilePage(),
        const JobSearchPage(),
        const ConversationsPage(),
        const AccountPage(),
      ];

  static const _professionalDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Painel',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
    NavigationDestination(
      icon: Icon(Icons.work_outline),
      selectedIcon: Icon(Icons.work),
      label: 'Vagas',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Mensagens',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: 'Conta',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Disponibiliza o cubit de notificações para as abas (sino 🔔).
    return BlocProvider.value(
      value: _notificationsCubit,
      // BlocConsumer = BlocBuilder (redesenha) + BlocListener (reage a mudanças).
      child: BlocConsumer<SessionCubit, SessionState>(
        // Só reage quando o MODO muda.
        listenWhen: (previous, current) => previous.mode != current.mode,
        // Ao trocar de modo, volta para a aba Início.
        listener: (context, state) => setState(() => _currentIndex = 0),
        buildWhen: (previous, current) => previous.mode != current.mode,
        builder: (context, session) {
          final isRecruiterMode = session.isRecruiterMode;

          if (isRecruiterMode) _projectsCreated = true;
          final pages = isRecruiterMode ? _recruiterPages() : _professionalPages();

          // Garante um índice válido ao trocar de modo (antes de o listener
          // voltar para a primeira aba).
          final currentIndex = _currentIndex.clamp(0, pages.length - 1);

          final scaffold = Scaffold(
            // IndexedStack mantém as abas "vivas" ao trocar entre elas.
            // A `key` muda com o modo: as abas são recriadas do zero quando
            // o usuário alterna entre profissional e contratante.
            body: IndexedStack(
              key: ValueKey(session.mode),
              index: currentIndex,
              children: pages,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: _goToTab,
              destinations:
                  isRecruiterMode ? _recruiterDestinations : _professionalDestinations,
            ),
          );

          // Só o modo Contratar precisa dos projetos.
          return isRecruiterMode
              ? BlocProvider.value(value: _projectsCubit, child: scaffold)
              : scaffold;
        },
      ),
    );
  }
}
