// =============================================================================
// core/widgets/maps/osm_tile_layer.dart
// -----------------------------------------------------------------------------
// CAMADA DE MAPA do OpenStreetMap (OSM).
//
// Um mapa digital é formado por "tiles" (ladrilhos): pequenas imagens
// quadradas que, lado a lado, formam o mapa. Cada nível de zoom tem seus
// próprios tiles. O OpenStreetMap fornece esses tiles gratuitamente.
//
// O endereço tem o formato .../{z}/{x}/{y}.png:
//   z = nível de zoom; x e y = posição do tile naquele nível.
// =============================================================================

import 'package:flutter_map/flutter_map.dart';

/// Cria a camada de tiles do OpenStreetMap usada em todos os mapas do app.
TileLayer buildOsmTileLayer() {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    // Identificação do app, exigida pela política de uso do OpenStreetMap.
    userAgentPackageName: 'com.seuprojeto.audiovisual_app',
  );
}
