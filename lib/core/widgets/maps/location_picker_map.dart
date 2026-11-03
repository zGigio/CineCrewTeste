// =============================================================================
// core/widgets/maps/location_picker_map.dart
// -----------------------------------------------------------------------------
// MAPA PARA ESCOLHER UM LOCAL tocando na tela.
//
// Usado ao publicar uma vaga: o contratante toca no mapa para marcar onde
// será a gravação. Também há um botão para centralizar na posição do GPS.
// O ponto escolhido é avisado à tela "mãe" pelo callback [onChanged].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../di/injection.dart';
import '../../services/location/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../app_feedback.dart';
import 'osm_tile_layer.dart';

class LocationPickerMap extends StatefulWidget {
  /// Ponto inicial (ex.: localização salva no perfil). Pode ser nulo.
  final LatLng? initialPoint;

  /// Chamado sempre que o usuário escolhe um novo ponto.
  final ValueChanged<LatLng> onChanged;

  final double height;

  const LocationPickerMap({
    super.key,
    this.initialPoint,
    required this.onChanged,
    this.height = 260,
  });

  /// Centro padrão quando não há ponto inicial: Rio de Janeiro.
  static const LatLng defaultCenter = LatLng(-22.9068, -43.1729);

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  /// Controlador do mapa: permite mover a câmera por código.
  final MapController _mapController = MapController();

  /// Ponto atualmente marcado (nulo até o usuário escolher).
  LatLng? _selected;

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPoint;
  }

  /// Marca o ponto tocado e avisa a tela mãe.
  void _select(LatLng point) {
    setState(() => _selected = point);
    widget.onChanged(point);
  }

  /// Pega a posição do GPS, marca e centraliza o mapa nela.
  Future<void> _useMyLocation() async {
    setState(() => _isLocating = true);
    final result = await getIt<LocationService>().getCurrentPosition();
    if (!mounted) return;
    setState(() => _isLocating = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (position) {
        final point = LatLng(position.latitude, position.longitude);
        _select(point);
        _mapController.move(point, 15); // centraliza com zoom 15
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        // Stack: empilha o botão de GPS por cima do mapa.
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selected ?? LocationPickerMap.defaultCenter,
                initialZoom: _selected != null ? 15 : 11,
                // Ao tocar no mapa, recebemos a coordenada do ponto tocado.
                onTap: (tapPosition, point) => _select(point),
              ),
              children: [
                buildOsmTileLayer(),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          size: 44,
                          color: AppColors.error, // pino vermelho, como nas pranchas
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Botão "minha localização" no canto inferior direito.
            Positioned(
              right: 8,
              bottom: 8,
              child: FloatingActionButton.small(
                heroTag: null, // evita conflito com outros botões flutuantes
                tooltip: 'Usar minha localização',
                onPressed: _isLocating ? null : _useMyLocation,
                child: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
            // Dica no topo enquanto nada foi escolhido.
            if (_selected == null)
              const Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Toque no mapa para marcar o local da gravação',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
