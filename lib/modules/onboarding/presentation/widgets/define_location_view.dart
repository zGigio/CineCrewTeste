// =============================================================================
// modules/onboarding/presentation/widgets/define_location_view.dart
// -----------------------------------------------------------------------------
// TEL08 — DEFINIR LOCALIZAÇÃO (componente COMPARTILHADO entre os modos):
//   * modo Profissional: "Onde você atua" (localização-base);
//   * modo Contratar:    "Local do set" (Parte 12).
//
//   [ Endereço | No mapa ]
//   Endereço ou CEP: [🔍 Rua Exemplo, 100 · Centro · RJ ]
//   [ mapa com o ponto ]
//   [ 🔍 Localizar ]  [ ⌖ Minha posição ]
//   Seu endereço exato não é exibido a contratantes.
//
// Estados alternativos:
//   * TEL08-E1: permissão de localização negada -> banner + aba "No mapa";
//   * TEL08-E2: endereço não encontrado -> banner; nenhum ponto é escolhido.
// Endereço ambíguo (vários resultados) também não gera coordenada sozinho:
// a pessoa escolhe qual é o certo na lista.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/services/geocoding/geocoding_service.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/maps/location_picker_map.dart';
import '../../../../core/widgets/maps/map_preview.dart';

enum _LocationTab { address, map }

class DefineLocationView extends StatefulWidget {
  /// Título da seção ("Onde você atua" ou "Local do set").
  final String heading;

  /// Ponto já salvo (edição). Pode ser nulo.
  final GeoPlace? initialPlace;

  /// Avisado a cada ponto escolhido (ou `null` quando o ponto é descartado).
  final ValueChanged<GeoPlace?> onChanged;

  /// Aviso de privacidade embaixo dos botões.
  final String privacyNote;

  const DefineLocationView({
    super.key,
    required this.heading,
    required this.onChanged,
    this.initialPlace,
    this.privacyNote = 'Seu endereço exato não é exibido a contratantes.',
  });

  @override
  State<DefineLocationView> createState() => _DefineLocationViewState();
}

class _DefineLocationViewState extends State<DefineLocationView> {
  final _queryController = TextEditingController();
  _LocationTab _tab = _LocationTab.address;
  GeoPlace? _place;

  /// Vários resultados para o mesmo endereço: a pessoa escolhe um.
  List<GeoPlace> _options = const [];

  /// Banner de erro/alerta atual (E1 ou E2), ou `null`.
  AppBanner? _banner;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _setPlace(GeoPlace? place) {
    setState(() {
      _place = place;
      _options = const [];
    });
    widget.onChanged(place);
  }

  /// "Localizar": geocodifica o endereço ou CEP digitado.
  Future<void> _search() async {
    FocusScope.of(context).unfocus(); // fecha o teclado
    setState(() {
      _isBusy = true;
      _banner = null;
      _options = const [];
    });
    final result = await getIt<GeocodingService>().search(_queryController.text);
    if (!mounted) return;
    setState(() => _isBusy = false);

    result.fold(
      (failure) => setState(() => _banner = AppBanner.error(failure.message)),
      (places) {
        if (places.isEmpty) {
          // TEL08-E2: endereço não encontrado -> nenhum ponto escolhido.
          _setPlace(null);
          setState(() => _banner = const AppBanner.error(
                'Não encontramos este endereço. Revise os dados ou marque o ponto no mapa.',
              ));
        } else if (places.length == 1) {
          _setPlace(places.first);
        } else {
          // Ambíguo: mostra as opções e espera a escolha.
          _setPlace(null);
          setState(() => _options = places);
        }
      },
    );
  }

  /// "Minha posição": usa o GPS (se a pessoa permitir).
  Future<void> _useMyPosition() async {
    setState(() {
      _isBusy = true;
      _banner = null;
    });
    final result = await getIt<LocationService>().getCurrentPosition();
    if (!mounted) return;

    await result.fold<Future<void>>(
      (failure) async {
        // TEL08-E1: sem permissão -> alerta e oferece o mapa.
        setState(() {
          _isBusy = false;
          _tab = _LocationTab.map;
          _banner = AppBanner.warning(
            failure is LocationFailure
                ? 'Permissão de localização negada. Informe o endereço ou marque o ponto no mapa.'
                : failure.message,
          );
        });
      },
      (position) async {
        final place = await getIt<GeocodingService>().reverse(
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;
        setState(() => _isBusy = false);
        _setPlace(place);
      },
    );
  }

  /// Ponto tocado no mapa: descobre cidade/UF para o rótulo.
  Future<void> _onMapPoint(LatLng point) async {
    setState(() => _isBusy = true);
    final place = await getIt<GeocodingService>().reverse(point.latitude, point.longitude);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _banner = null;
    });
    _setPlace(place);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = _place;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.heading, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<_LocationTab>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _LocationTab.address, label: Text('Endereço')),
            ButtonSegment(value: _LocationTab.map, label: Text('No mapa')),
          ],
          selected: {_tab},
          onSelectionChanged: (selection) => setState(() => _tab = selection.first),
        ),
        const SizedBox(height: 12),
        if (_banner != null) ...[_banner!, const SizedBox(height: 12)],

        if (_tab == _LocationTab.address) ...[
          LabeledField(
            label: 'Endereço ou CEP',
            child: TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'Rua, número, bairro e cidade — ou o CEP',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Endereço ambíguo: lista para escolher.
          if (_options.isNotEmpty) ...[
            Text('Qual destes?', style: theme.textTheme.titleSmall),
            for (final option in _options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(option.label),
                onTap: () => _setPlace(option),
              ),
          ] else if (place != null)
            // IgnorePointer: o mapa aqui é só uma prévia.
            IgnorePointer(
              child: MapPreview(
                key: ValueKey('${place.latitude},${place.longitude}'),
                latitude: place.latitude,
                longitude: place.longitude,
                height: 170,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Localizar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _useMyPosition,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Minha posição'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Aba "No mapa": toque para marcar o ponto.
          LocationPickerMap(
            // A key muda quando o ponto vem de fora (busca/GPS): o mapa
            // é recriado já centralizado nele.
            key: ValueKey(place == null ? 'vazio' : '${place.latitude},${place.longitude}'),
            initialPoint: place == null ? null : LatLng(place.latitude, place.longitude),
            onChanged: _onMapPoint,
          ),
          const SizedBox(height: 6),
          Text('Toque no mapa para marcar o ponto.', style: theme.textTheme.bodySmall),
        ],

        if (_isBusy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (place != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.place, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(child: Text(place.label, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(widget.privacyNote, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
