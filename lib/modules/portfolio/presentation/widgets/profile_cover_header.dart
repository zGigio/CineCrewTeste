// =============================================================================
// modules/portfolio/presentation/widgets/profile_cover_header.dart
// -----------------------------------------------------------------------------
// CABEÇALHO ESTILO LINKEDIN:
//
//   ┌───────────────────────────────────────┐
//   │            FOTO DE CAPA               │
//   │  ( FOTO )                             │
//   └──(PERFIL)─────────────────────────────┘
//   Nome Completo
//   Título profissional (headline)
//   Função · Cidade - UF          ★★★★⯪ 4,7 (12)
//
// Sem capa, o topo usa um degradê com as cores do tema "cinema escuro".
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../reviews/presentation/widgets/rating_stars.dart';

class ProfileCoverHeader extends StatelessWidget {
  final UserProfile profile;

  /// Botão opcional sobre a capa (ex.: "Trocar capa" na edição).
  final Widget? coverAction;

  /// Linha de distância (TEL14): "≈ 9 km do set · localização aproximada".
  final String? distanceLabel;

  const ProfileCoverHeader({
    super.key,
    required this.profile,
    this.coverAction,
    this.distanceLabel,
  });

  static const double coverHeight = 150;
  static const double avatarRadius = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = [
      if (profile.primaryRole != null && profile.primaryRole!.isNotEmpty) profile.primaryRole!,
      if (profile.companyName != null && profile.companyName!.isNotEmpty) profile.companyName!,
      if (profile.locationLabel.isNotEmpty) profile.locationLabel,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stack: a foto de perfil fica metade sobre a capa.
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: coverHeight,
              width: double.infinity,
              child: profile.hasCover
                  ? Image.network(
                      profile.coverUrl!,
                      fit: BoxFit.cover,
                      // Se a imagem não carregar, mostra o degradê.
                      errorBuilder: (_, _, _) => const _CoverGradient(),
                    )
                  : const _CoverGradient(),
            ),
            if (coverAction != null) Positioned(right: 8, top: 8, child: coverAction!),
            Positioned(
              left: 16,
              bottom: -avatarRadius,
              child: CircleAvatar(
                // Anel com a cor do fundo, separando a foto da capa.
                radius: avatarRadius + 4,
                backgroundColor: colors.surface,
                child: UserAvatar(
                  imageUrl: profile.avatarUrl,
                  name: profile.fullName,
                  radius: avatarRadius,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: avatarRadius + 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.isEmpty ? 'Usuário' : profile.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (distanceLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  distanceLabel!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (profile.headline != null && profile.headline!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(profile.headline!, style: theme.textTheme.titleMedium),
              ],
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (profile.rating > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingStars(rating: profile.rating),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.rating.toStringAsFixed(1).replaceAll('.', ',')}'
                      '${profile.reviewsCount > 0 ? ' (${profile.reviewsCount})' : ''}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Degradê âmbar -> escuro (capa padrão).
class _CoverGradient extends StatelessWidget {
  const _CoverGradient();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary.withValues(alpha: 0.75), colors.surfaceContainerHighest],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Icon(
            Icons.movie_creation_outlined,
            size: 72,
            color: colors.onSurface.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }
}
