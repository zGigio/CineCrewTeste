// =============================================================================
// modules/portfolio/presentation/widgets/portfolio_tile.dart
// -----------------------------------------------------------------------------
// MINIATURA QUADRADA de um item do portfólio (grade de 3 colunas):
//   * foto -> a própria imagem;
//   * vídeo -> capa do YouTube (quando há) com o ícone ▶ por cima.
// Tocar abre a foto em tela cheia ou o vídeo no app do site.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/portfolio_item.dart';
import '../pages/photo_viewer_page.dart';

class PortfolioTile extends StatelessWidget {
  final PortfolioItem item;

  /// Toque longo (na edição: apagar).
  final VoidCallback? onLongPress;

  const PortfolioTile({super.key, required this.item, this.onLongPress});

  Future<void> _open(BuildContext context) async {
    if (!item.isVideo) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PhotoViewerPage(item: item)),
      );
      return;
    }
    // Vídeo: abre fora do app (YouTube, Vimeo, Instagram...).
    final opened = await launchUrl(
      Uri.parse(item.videoUrl!),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showAppMessage(context, 'Não foi possível abrir o vídeo.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final thumbnail = item.thumbnailUrl;

    return Semantics(
      label: '${item.type.label}: ${item.title}',
      button: true,
      child: InkWell(
        onTap: () => _open(context),
        onLongPress: onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null)
                Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Placeholder(item: item),
                )
              else
                _Placeholder(item: item),
              if (item.isVideo)
                Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.play_arrow, color: colors.primary),
                  ),
                ),
              // Título na parte de baixo, sobre uma faixa escura.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fundo quando não há miniatura (ex.: vídeo do Vimeo).
class _Placeholder extends StatelessWidget {
  final PortfolioItem item;

  const _Placeholder({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Icon(
        item.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
