// =============================================================================
// modules/explore/presentation/widgets/filters_sheet.dart
// -----------------------------------------------------------------------------
// TEL12-E4 — PAINEL DE FILTROS (sobe de baixo, sobre os resultados):
//   Especialidades (chips) · Raio máximo (km) · Somente disponíveis
//   [ Limpar ]  [ Aplicar ]
// Devolve os critérios novos, ou `null` se fechar sem aplicar.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../domain/entities/search_criteria.dart';
import '../../domain/search_rules.dart';

Future<SearchCriteria?> showFiltersSheet(BuildContext context, SearchCriteria criteria) {
  return showModalBottomSheet<SearchCriteria>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FiltersSheet(initial: criteria),
  );
}

class _FiltersSheet extends StatefulWidget {
  final SearchCriteria initial;

  const _FiltersSheet({required this.initial});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late List<String> _specialties;
  late bool _onlyAvailable;
  late final TextEditingController _radiusController;
  String? _radiusError;
  String? _specialtiesError;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _specialties = List.of(widget.initial.specialties);
    _onlyAvailable = widget.initial.onlyAvailable;
    _radiusController = TextEditingController(text: '${widget.initial.radiusKm}');
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  /// "Limpar": volta aos padrões (raio 50 km, todos, sem especialidades).
  void _clear() {
    setState(() {
      _specialties = [];
      _onlyAvailable = false;
      _radiusController.text = '${RadiusRules.defaultKm}';
      _radiusError = null;
      _specialtiesError = null;
    });
  }

  void _apply() {
    final radius = int.tryParse(_radiusController.text.trim());
    setState(() {
      _radiusError = SearchRules.radius(radius);
      _specialtiesError =
          _specialties.isEmpty ? 'Selecione ao menos uma especialidade' : null;
    });
    if (_radiusError != null || _specialtiesError != null) return;
    Navigator.of(context).pop(
      widget.initial.copyWith(
        specialties: List.of(_specialties),
        radiusKm: radius,
        onlyAvailable: _onlyAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mostra primeiro as escolhidas; o resto do catálogo em "+ mais".
    final visible = _showAll
        ? audiovisualRoles
        : {..._specialties, ...audiovisualRoles.take(4)}.toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Filtros', style: theme.textTheme.titleLarge)),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Especialidades', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in visible)
                  FilterChip(
                    label: Text(role),
                    selected: _specialties.contains(role),
                    onSelected: (selected) => setState(() {
                      selected ? _specialties.add(role) : _specialties.remove(role);
                    }),
                  ),
                if (!_showAll)
                  ActionChip(
                    label: const Text('+ mais'),
                    onPressed: () => setState(() => _showAll = true),
                  ),
              ],
            ),
            if (_specialtiesError != null) ...[
              const SizedBox(height: 6),
              Text(_specialtiesError!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            LabeledField(
              label: 'Raio máximo (km)',
              child: TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  errorText: _radiusError,
                  helperText: 'Entre ${RadiusRules.min} e ${RadiusRules.max} km',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente disponíveis'),
              subtitle: const Text('Esconde quem marcou "indisponível no momento"'),
              value: _onlyAvailable,
              onChanged: (value) => setState(() => _onlyAvailable = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _clear, child: const Text('Limpar')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _apply, child: const Text('Aplicar')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
