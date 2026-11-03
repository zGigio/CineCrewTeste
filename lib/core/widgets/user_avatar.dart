// =============================================================================
// core/widgets/user_avatar.dart
// -----------------------------------------------------------------------------
// FOTO DE PERFIL redonda.
//
// Se o usuário tiver foto, mostra a imagem (baixada pela internet).
// Se não tiver, mostra as INICIAIS do nome (ex.: "Leonardo Santos" -> "LS"),
// como fazem o LinkedIn e o Gmail.
// =============================================================================

import 'package:flutter/material.dart';

/// Avatar circular com foto ou iniciais.
class UserAvatar extends StatelessWidget {
  /// Endereço (URL) da foto. Pode ser nulo.
  final String? imageUrl;

  /// Nome da pessoa, usado para gerar as iniciais.
  final String name;

  /// Raio do círculo (metade do diâmetro).
  final double radius;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
  });

  /// Pega a primeira letra do primeiro e do último nome.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      // NetworkImage baixa a foto pela internet e guarda em cache.
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      // As iniciais só aparecem quando não há foto.
      child: hasImage
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
