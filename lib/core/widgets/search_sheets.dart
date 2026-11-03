// =============================================================================
// core/widgets/search_sheets.dart
// -----------------------------------------------------------------------------
// JANELAS DE ESCOLHA da busca (abrem de baixo para cima: "bottom sheets").
//
//   * showWherePicker: ONDE buscar (GPS ou endereço do perfil) + raio em km;
//   * showRolePicker:  QUAL FUNÇÃO (lista padronizada do audiovisual).
// =============================================================================

import 'package:flutter/material.dart';

import '../constants/audiovisual_roles.dart';

/// De onde vem o ponto central da busca.
enum SearchOrigin {
  gps('Minha localização atual'),
  profile('Endereço do meu perfil');

  const SearchOrigin(this.label);
  final String label;
}

/// Resultado da escolha de "Onde": origem + raio.
class WhereChoice {
  final SearchOrigin origin;
  final double radiusKm;

  const WhereChoice({required this.origin, required this.radiusKm});
}

/// Abre a janela de "Onde". Devolve `null` se o usuário fechar sem aplicar.
///
/// [profileHasLocation] desativa a opção "perfil" quando o usuário ainda
/// não salvou uma localização no perfil.
Future<WhereChoice?> showWherePicker(
  BuildContext context, {
  required WhereChoice current,
  required bool profileHasLocation,
}) {
  // Valores editáveis dentro da janela (começam com a escolha atual).
  var origin = current.origin;
  var radius = current.radiusKm;

  return showModalBottomSheet<WhereChoice>(
    context: context,
    showDragHandle: true, // "alça" no topo para arrastar e fechar
    builder: (sheetContext) {
      // StatefulBuilder: permite atualizar só o conteúdo da janela
      // (o slider se mexendo) sem redesenhar a tela inteira.
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Onde?', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SegmentedButton<SearchOrigin>(
                  segments: [
                    const ButtonSegment(
                      value: SearchOrigin.gps,
                      label: Text('GPS'),
                      icon: Icon(Icons.my_location),
                    ),
                    ButtonSegment(
                      value: SearchOrigin.profile,
                      label: const Text('Meu perfil'),
                      icon: const Icon(Icons.home_outlined),
                      enabled: profileHasLocation,
                    ),
                  ],
                  selected: {origin},
                  onSelectionChanged: (selection) =>
                      setSheetState(() => origin = selection.first),
                ),
                const SizedBox(height: 24),
                Text('Raio de busca: ${radius.round()} km'),
                // Slider: barra deslizante de 1 a 200 km.
                Slider(
                  value: radius,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  label: '${radius.round()} km',
                  onChanged: (value) => setSheetState(() => radius = value),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(
                    WhereChoice(origin: origin, radiusKm: radius.roundToDouble()),
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Abre a lista de funções. Devolve:
///   - a função escolhida;
///   - '' (texto vazio) se escolher "Qualquer função";
///   - `null` se fechar sem escolher.
Future<String?> showRolePicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // permite a janela ocupar mais altura
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('Qualquer função'),
                trailing: (selected == null || selected.isEmpty)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
              const Divider(),
              for (final role in audiovisualRoles)
                ListTile(
                  title: Text(role),
                  trailing: role == selected ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(sheetContext).pop(role),
                ),
            ],
          );
        },
      );
    },
  );
}
