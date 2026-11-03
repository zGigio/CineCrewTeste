// =============================================================================
// core/widgets/airbnb_search_bar.dart
// -----------------------------------------------------------------------------
// BARRA DE BUSCA no estilo do Airbnb:
//
//   ( Onde            | Quando          | Função          [ 🔍 ] )
//     Perto de mim      Qualquer data     Qualquer função
//
// Cada "segmento" mostra um título e o valor escolhido; ao tocar, abre a
// escolha correspondente. O botão redondo à direita executa a busca.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Um segmento da barra (ex.: "Onde" / "Perto de mim · 25 km").
class SearchSegment {
  final String label;
  final String value;
  final VoidCallback onTap;

  const SearchSegment({
    required this.label,
    required this.value,
    required this.onTap,
  });
}

class AirbnbSearchBar extends StatelessWidget {
  final List<SearchSegment> segments;
  final VoidCallback onSearch;
  final bool isLoading;

  const AirbnbSearchBar({
    super.key,
    required this.segments,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Material com elevação: dá a sombra suave da "pílula" do Airbnb.
    return Material(
      elevation: 3,
      shadowColor: Colors.black54,
      // No tema escuro, a "pílula" usa a superfície elevada para se destacar.
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Row(
          children: [
            // Um bloco por segmento, separados por uma linha vertical fina.
            for (var i = 0; i < segments.length; i++) ...[
              Expanded(child: _SegmentView(segment: segments[i])),
              if (i < segments.length - 1)
                Container(
                  width: 1,
                  height: 32,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
            const SizedBox(width: 4),
            // Botão de busca redondo, na cor de destaque.
            IconButton.filled(
              tooltip: 'Buscar',
              onPressed: isLoading ? null : onSearch,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black, // ícone preto sobre o âmbar
                minimumSize: const Size(48, 48),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenho de um segmento: título em negrito + valor em cinza.
class _SegmentView extends StatelessWidget {
  final SearchSegment segment;

  const _SegmentView({required this.segment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segment.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              segment.value,
              // Uma linha só, com "..." se o texto não couber.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
