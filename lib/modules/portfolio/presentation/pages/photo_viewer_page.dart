// =============================================================================
// modules/portfolio/presentation/pages/photo_viewer_page.dart
// -----------------------------------------------------------------------------
// FOTO EM TELA CHEIA, com zoom de pinça (InteractiveViewer) e o título e a
// descrição embaixo.
// =============================================================================

import 'package:flutter/material.dart';

import '../../domain/entities/portfolio_item.dart';

class PhotoViewerPage extends StatelessWidget {
  final PortfolioItem item;

  const PhotoViewerPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4, // até 4x de zoom
              child: Center(
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          if (item.description != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(item.description!, style: const TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
    );
  }
}
