// =============================================================================
// modules/home/presentation/widgets/category_carousel.dart
// -----------------------------------------------------------------------------
// CARROSSEL DE CATEGORIAS (como as categorias do topo do Airbnb).
//
//   (🎥)       (📷)        (🎙)    (🚁)    ...
//  Videomaker  Fotografia   Som    Drone
//
// Tocar em uma categoria abre a busca de vagas já filtrada por ela.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/role_icons.dart';

class CategoryCarousel extends StatelessWidget {
  /// Chamado com a categoria tocada.
  final ValueChanged<RoleCategory> onSelected;

  const CategoryCarousel({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 92,
      // ListView horizontal: rola para os lados.
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: featuredCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = featuredCategories[index];
          return InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  // Círculo com o ícone da função.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(category.icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
