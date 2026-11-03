// =============================================================================
// modules/explore/presentation/widgets/search_summary_pill.dart
// -----------------------------------------------------------------------------
// PÍLULA DE RESUMO DA BUSCA (topo de TEL12/TEL13):
//
//   📍 Petrolina · PE                         [ ⚙ Filtros ]
//      Raio 50 km · 2 especialidades
//
// Tocar no resumo edita a busca (TEL11); "Filtros" abre o painel (TEL12-E4).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_criteria.dart';

class SearchSummaryPill extends StatelessWidget {
  final SearchCriteria criteria;
  final VoidCallback onEdit;
  final VoidCallback onFilters;

  const SearchSummaryPill({
    super.key,
    required this.criteria,
    required this.onEdit,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.place, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criteria.placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      criteria.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size(48, 44),
                ),
                onPressed: onFilters,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
