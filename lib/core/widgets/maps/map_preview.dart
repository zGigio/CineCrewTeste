// =============================================================================
// core/widgets/maps/map_preview.dart
// -----------------------------------------------------------------------------
// MAPA DE VISUALIZAÇÃO (somente leitura) com um alfinete no local.
// Usado no detalhe da vaga para mostrar ONDE será o trabalho.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'osm_tile_layer.dart';

class MapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;

  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    // LatLng: tipo do pacote latlong2 que representa uma coordenada.
    final point = LatLng(latitude, longitude);

    return SizedBox(
      height: height,
      // ClipRRect: arredonda os cantos do mapa.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            // InteractiveFlag.none: o mapa fica "parado" (sem arrastar/zoom),
            // para não atrapalhar a rolagem da tela.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            buildOsmTileLayer(),
            // Camada de marcadores: o alfinete no local da vaga.
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    size: 44,
                    color: AppColors.error, // pino vermelho (padrão das pranchas)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
