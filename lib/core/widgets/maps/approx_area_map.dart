// =============================================================================
// core/widgets/maps/approx_area_map.dart
// -----------------------------------------------------------------------------
// MAPA DE ÁREA APROXIMADA (perfil de OUTRA pessoa).
//
// Em vez de um pino no endereço, mostra um CÍRCULO de ~1 km em volta da
// posição aproximada que o banco devolve (grade de 0,01 grau). Assim quem
// vê sabe a região, mas nunca o endereço (RN35/RN36, LGPD).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'osm_tile_layer.dart';

class ApproxAreaMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;

  /// Raio do círculo, em metros.
  static const double radiusMeters = 1200;

  const ApproxAreaMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    return Semantics(
      label: 'Mapa com a área aproximada onde a pessoa atua',
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              buildOsmTileLayer(),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: radiusMeters,
                    useRadiusInMeter: true,
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderColor: AppColors.accent,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
