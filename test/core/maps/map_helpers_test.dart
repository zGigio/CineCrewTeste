// =============================================================================
// test/core/maps/map_helpers_test.dart
// -----------------------------------------------------------------------------
// Testes dos auxiliares de mapa da Parte 6:
//   - RadiusMap.zoomForRadius: zoom inicial adequado ao raio da busca;
//   - iconForRole / featuredCategories: ícones das categorias.
// Rodar com: flutter test
// =============================================================================

import 'package:audiovisual_app/core/constants/audiovisual_roles.dart';
import 'package:audiovisual_app/core/constants/role_icons.dart';
import 'package:audiovisual_app/core/widgets/maps/radius_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadiusMap.zoomForRadius', () {
    test('raio maior => zoom menor (mapa mais "afastado")', () {
      expect(
        RadiusMap.zoomForRadius(5),
        greaterThan(RadiusMap.zoomForRadius(50)),
      );
    });

    test('dobrar o raio diminui o zoom em 1 nível', () {
      final diff = RadiusMap.zoomForRadius(10) - RadiusMap.zoomForRadius(20);
      expect(diff, closeTo(1, 0.0001));
    });

    test('o zoom fica sempre entre 3 e 16', () {
      expect(RadiusMap.zoomForRadius(0), lessThanOrEqualTo(16));
      expect(RadiusMap.zoomForRadius(100000), greaterThanOrEqualTo(3));
    });
  });

  group('Ícones das categorias', () {
    test('função conhecida devolve o ícone da categoria', () {
      expect(iconForRole('Videomaker'), Icons.videocam);
      expect(iconForRole('Operador(a) de Drone'), Icons.flight);
    });

    test('função desconhecida ou nula devolve o ícone padrão', () {
      expect(iconForRole(null), Icons.movie_creation_outlined);
      expect(iconForRole('Função inventada'), Icons.movie_creation_outlined);
    });

    test('toda categoria aponta para uma função da lista oficial', () {
      for (final category in featuredCategories) {
        expect(audiovisualRoles, contains(category.role), reason: category.label);
      }
    });
  });
}
