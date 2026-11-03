// =============================================================================
// modules/portfolio/presentation/pages/manage_portfolio_page.dart
// -----------------------------------------------------------------------------
// TELA "PORTFÓLIO E EXPERIÊNCIAS" (edição do próprio perfil), com 2 abas:
//   * Portfólio: adicionar FOTO (galeria) ou VÍDEO (link); toque longo apaga;
//   * Experiências: adicionar, editar (toque) e apagar (lixeira).
// Tudo aparece no perfil público, como no LinkedIn.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/portfolio_item.dart';
import '../cubit/portfolio_cubit.dart';
import '../widgets/experience_tile.dart';
import '../widgets/media_details_dialog.dart';
import '../widgets/profile_showcase.dart';
import 'experience_form_page.dart';

class ManagePortfolioPage extends StatelessWidget {
  const ManagePortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;
    return BlocProvider(
      create: (_) => getIt<PortfolioCubit>()..load(userId),
      // DefaultTabController: controla as abas sem precisar de estado próprio.
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Portfólio e experiências'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.photo_library_outlined), text: 'Portfólio'),
                Tab(icon: Icon(Icons.work_history_outlined), text: 'Experiências'),
              ],
            ),
          ),
          body: BlocBuilder<PortfolioCubit, PortfolioState>(
            builder: (context, state) {
              if (state.isLoading) return const Center(child: CircularProgressIndicator());
              return Column(
                children: [
                  // Barra fina de progresso enquanto envia/salva.
                  if (state.isBusy) const LinearProgressIndicator(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PortfolioTab(state: state),
                        _ExperiencesTab(state: state),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ABA PORTFÓLIO
// =============================================================================
class _PortfolioTab extends StatelessWidget {
  final PortfolioState state;

  const _PortfolioTab({required this.state});

  Future<void> _addPhoto(BuildContext context) async {
    final cubit = context.read<PortfolioCubit>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, // reduz o tamanho sem perder qualidade na tela
      imageQuality: 82,
    );
    if (picked == null || !context.mounted) return;
    final details = await showMediaDetailsDialog(context, isVideo: false);
    if (details == null || !context.mounted) return;

    final bytes = await picked.readAsBytes();
    final error = await cubit.addPhoto(bytes, details.title, details.description);
    if (context.mounted) _showResult(context, error, 'Foto adicionada ao portfólio!');
  }

  Future<void> _addVideo(BuildContext context) async {
    final cubit = context.read<PortfolioCubit>();
    final details = await showMediaDetailsDialog(context, isVideo: true);
    if (details == null || !context.mounted) return;
    final error = await cubit.addVideo(details.url, details.title, details.description);
    if (context.mounted) _showResult(context, error, 'Vídeo adicionado ao portfólio!');
  }

  Future<void> _delete(BuildContext context, PortfolioItem item) async {
    final cubit = context.read<PortfolioCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Apagar do portfólio?',
      message: '"${item.title}" deixará de aparecer no seu perfil.',
      confirmLabel: 'Apagar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await cubit.deleteItem(item);
    if (context.mounted) _showResult(context, error, 'Item apagado.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: state.isBusy ? null : () => _addPhoto(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: state.isBusy ? null : () => _addVideo(context),
                icon: const Icon(Icons.video_call_outlined),
                label: const Text('Vídeo (link)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Mostre seus melhores trabalhos. Toque e segure um item para apagar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (state.errorMessage != null)
          Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (state.items.isEmpty)
          const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Portfólio vazio',
            message: 'Adicione fotos de bastidores, frames ou links dos seus vídeos.',
          )
        else
          PortfolioGrid(items: state.items, onLongPress: (item) => _delete(context, item)),
      ],
    );
  }
}

// =============================================================================
// ABA EXPERIÊNCIAS
// =============================================================================
class _ExperiencesTab extends StatelessWidget {
  final PortfolioState state;

  const _ExperiencesTab({required this.state});

  Future<void> _openForm(BuildContext context, [Experience? experience]) async {
    final cubit = context.read<PortfolioCubit>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        // O formulário usa o MESMO cubit desta tela.
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ExperienceFormPage(experience: experience),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      showAppMessage(context, 'Experiência salva!');
    }
  }

  Future<void> _delete(BuildContext context, Experience experience) async {
    final cubit = context.read<PortfolioCubit>();
    final confirmed = await confirmAction(
      context,
      title: 'Apagar experiência?',
      message: '"${experience.role} · ${experience.production}" sairá do seu perfil.',
      confirmLabel: 'Apagar',
    );
    if (!confirmed || !context.mounted) return;
    final error = await cubit.deleteExperience(experience.id!);
    if (context.mounted) _showResult(context, error, 'Experiência apagada.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.tonalIcon(
          onPressed: state.isBusy ? null : () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Nova experiência'),
        ),
        const SizedBox(height: 16),
        if (state.experiences.isEmpty)
          const EmptyState(
            icon: Icons.work_history_outlined,
            title: 'Nenhuma experiência ainda',
            message: 'Conte em quais filmes, clipes, eventos e campanhas você já trabalhou.',
          )
        else
          for (final experience in state.experiences)
            ExperienceTile(
              experience: experience,
              onEdit: () => _openForm(context, experience),
              onDelete: () => _delete(context, experience),
            ),
      ],
    );
  }
}

/// Mostra o erro em vermelho, ou a mensagem de sucesso.
void _showResult(BuildContext context, String? error, String success) {
  showAppMessage(context, error ?? success, isError: error != null);
}
