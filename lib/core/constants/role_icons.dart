// =============================================================================
// core/constants/role_icons.dart
// -----------------------------------------------------------------------------
// ÍCONES DAS FUNÇÕES do audiovisual e CATEGORIAS EM DESTAQUE.
//
// Usados no carrossel de categorias da tela inicial (como as categorias
// "Praia", "Campo"... do Airbnb) e nos marcadores do mapa de talentos.
// =============================================================================

import 'package:flutter/material.dart';

/// Uma categoria do carrossel: nome curto + função da lista padronizada.
class RoleCategory {
  /// Nome curto exibido embaixo do ícone.
  final String label;

  /// Função correspondente em `audiovisualRoles` (usada no filtro da busca).
  final String role;

  final IconData icon;

  const RoleCategory(this.label, this.role, this.icon);
}

/// Categorias em destaque na tela inicial, na ordem do carrossel.
const List<RoleCategory> featuredCategories = [
  RoleCategory('Videomaker', 'Videomaker', Icons.videocam),
  RoleCategory('Fotografia', 'Fotógrafo(a) Still', Icons.photo_camera),
  RoleCategory('Som', 'Técnico(a) de Som Direto', Icons.mic),
  RoleCategory('Drone', 'Operador(a) de Drone', Icons.flight),
  RoleCategory('Edição', 'Editor(a) de Vídeo', Icons.content_cut),
  RoleCategory('Dir. Fotografia', 'Diretor(a) de Fotografia', Icons.camera_roll),
  RoleCategory('Iluminação', 'Gaffer / Eletricista', Icons.lightbulb),
  RoleCategory('Maquiagem', 'Maquiador(a)', Icons.brush),
  RoleCategory('Produção', 'Produtor(a)', Icons.assignment_ind),
];

/// Ícone de uma função qualquer (usa o da categoria, ou um ícone genérico).
IconData iconForRole(String? role) {
  for (final category in featuredCategories) {
    if (category.role == role) return category.icon;
  }
  return Icons.movie_creation_outlined;
}
