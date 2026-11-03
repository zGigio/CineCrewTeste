// =============================================================================
// modules/reviews/presentation/widgets/rating_stars.dart
// -----------------------------------------------------------------------------
// ESTRELAS DE AVALIAÇÃO:
//   * RatingStars      -> só exibe (aceita meia estrela: 4,5 = ★★★★⯪);
//   * StarRatingInput  -> o usuário toca para escolher de 1 a 5.
// =============================================================================

import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  /// Nota de 0 a 5 (pode ter casa decimal).
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            // Estrela cheia, meia ou vazia, conforme a nota.
            rating >= i
                ? Icons.star
                : rating >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: color,
          ),
      ],
    );
  }
}

class StarRatingInput extends StatelessWidget {
  /// Nota escolhida (0 = nenhuma ainda).
  final int value;
  final ValueChanged<int> onChanged;

  const StarRatingInput({super.key, required this.value, required this.onChanged});

  static const _labels = ['Ruim', 'Regular', 'Bom', 'Muito bom', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                tooltip: '$i de 5',
                iconSize: 40,
                onPressed: () => onChanged(i),
                icon: Icon(
                  i <= value ? Icons.star : Icons.star_border,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        Text(
          value == 0 ? 'Toque nas estrelas' : _labels[value - 1],
          style: theme.textTheme.titleSmall,
        ),
      ],
    );
  }
}
