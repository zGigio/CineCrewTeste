// =============================================================================
// modules/portfolio/presentation/widgets/profile_showcase.dart
// -----------------------------------------------------------------------------
// SEÇÕES "EXPERIÊNCIA" e "PORTFÓLIO" do perfil público (somente leitura).
// Carrega as duas listas do usuário e mostra:
//   * Experiência: até 3 itens + "Ver todas";
//   * Portfólio: grade de miniaturas (3 por linha).
// Seções vazias não aparecem, para o perfil não ficar com "buracos".
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/portfolio_item.dart';
import '../../domain/repositories/portfolio_repository.dart';
import 'experience_tile.dart';
import 'portfolio_tile.dart';

class ProfileShowcase extends StatefulWidget {
  final String userId;

  const ProfileShowcase({super.key, required this.userId});

  @override
  State<ProfileShowcase> createState() => _ProfileShowcaseState();
}

class _ProfileShowcaseState extends State<ProfileShowcase> {
  static const int _previewExperiences = 3;

  List<PortfolioItem> _items = const [];
  List<Experience> _experiences = const [];
  bool _isLoading = true;
  bool _showAllExperiences = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = getIt<PortfolioRepository>();
    final itemsFuture = repository.getItems(widget.userId);
    final experiencesFuture = repository.getExperiences(widget.userId);
    final items = await itemsFuture;
    final experiences = await experiencesFuture;
    if (!mounted) return;
    setState(() {
      // Em caso de erro, a seção simplesmente não aparece.
      _items = items.getOrElse((_) => const []);
      _experiences = experiences.getOrElse((_) => const []);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final visibleExperiences = _showAllExperiences
        ? _experiences
        : _experiences.take(_previewExperiences).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_experiences.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Experiência', style: theme.textTheme.titleMedium),
          for (final experience in visibleExperiences) ExperienceTile(experience: experience),
          if (!_showAllExperiences && _experiences.length > _previewExperiences)
            TextButton(
              onPressed: () => setState(() => _showAllExperiences = true),
              child: Text('Ver todas as ${_experiences.length} experiências'),
            ),
        ],
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Portfólio', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          PortfolioGrid(items: _items),
        ],
      ],
    );
  }
}

/// Grade de miniaturas (3 por linha) que não rola sozinha: rola junto
/// com a tela onde está.
class PortfolioGrid extends StatelessWidget {
  final List<PortfolioItem> items;

  /// Toque longo em um item (usado na edição para apagar).
  final ValueChanged<PortfolioItem>? onLongPress;

  const PortfolioGrid({super.key, required this.items, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return PortfolioTile(
          item: item,
          onLongPress: onLongPress == null ? null : () => onLongPress!(item),
        );
      },
    );
  }
}
