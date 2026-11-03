// =============================================================================
// core/widgets/maps/radius_map.dart
// -----------------------------------------------------------------------------
// MAPA DE RESULTADOS DA BUSCA ESPACIAL.
//
// Desenha, sobre o OpenStreetMap:
//   1. o CÍRCULO do raio da busca (ex.: 25 km ao redor do usuário) — é a
//      representação visual da consulta ST_DWithin feita pelo PostGIS;
//   2. o ponto central ("Você está aqui");
//   3. os marcadores dos resultados (vagas ou profissionais), recebidos
//      prontos de quem usa este widget.
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'osm_tile_layer.dart';

class RadiusMap extends StatelessWidget {
  /// Centro da busca.
  final LatLng center;

  /// Raio da busca em quilômetros.
  final double radiusKm;

  /// Marcadores dos resultados.
  final List<Marker> markers;

  /// `true`: o centro é o LOCAL DO SET (pino vermelho, modo Contratar).
  /// `false`: o centro é "você" (ponto azul).
  final bool centerPin;

  const RadiusMap({
    super.key,
    required this.center,
    required this.radiusKm,
    required this.markers,
    this.centerPin = false,
  });

  /// Calcula um zoom que mostre o círculo inteiro na tela.
  ///
  /// No mapa, cada nível de zoom DOBRA a escala. Por isso o zoom diminui
  /// com o logaritmo (base 2) do raio: raio 1 km -> zoom 13,5;
  /// raio 25 km -> ~8,9; raio 200 km -> ~5,9.
  static double zoomForRadius(double radiusKm) {
    final safeRadius = math.max(radiusKm, 0.5);
    final zoom = 13.5 - math.log(safeRadius) / math.ln2;
    return zoom.clamp(3, 16).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoomForRadius(radiusKm),
      ),
      children: [
        buildOsmTileLayer(),
        // 1. Círculo do raio (em METROS reais, acompanha o zoom).
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusKm * 1000,
              useRadiusInMeter: true,
              color: AppTheme.accentColor.withValues(alpha: 0.10),
              borderColor: AppTheme.accentColor,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        // 2 e 3. Ponto central + marcadores dos resultados.
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: centerPin ? 40 : 22,
              height: centerPin ? 40 : 22,
              // O pino "aponta" para o ponto com a ponta de baixo.
              alignment: centerPin ? Alignment.topCenter : Alignment.center,
              child: centerPin
                  ? const Icon(Icons.location_on, size: 40, color: AppColors.error)
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
            ),
            ...markers,
          ],
        ),
      ],
    );
  }
}

/// Marcador em formato de "etiqueta" (pílula com texto), como os preços
/// que o Airbnb mostra no mapa. Tocar chama [onTap].
class LabelMarkerChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const LabelMarkerChip({super.key, required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.black),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
