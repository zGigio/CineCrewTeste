// =============================================================================
// modules/portfolio/domain/entities/portfolio_item.dart
// -----------------------------------------------------------------------------
// ENTIDADE: ITEM DO PORTFÓLIO — uma FOTO de um trabalho ou um VÍDEO (link do
// YouTube, Vimeo, Instagram, Google Drive...). Os vídeos não são enviados
// para o app: guardamos só o link, que abre no app do próprio site.
// =============================================================================

import 'package:equatable/equatable.dart';

enum PortfolioMediaType {
  photo('foto', 'Foto'),
  video('video', 'Vídeo');

  /// Texto gravado no banco.
  final String value;
  final String label;

  const PortfolioMediaType(this.value, this.label);

  static PortfolioMediaType fromValue(String? value) =>
      value == 'video' ? PortfolioMediaType.video : PortfolioMediaType.photo;
}

class PortfolioItem extends Equatable {
  final String id;
  final String userId;
  final PortfolioMediaType type;
  final String title;
  final String? description;

  /// Foto: caminho no Storage (usado para apagar o arquivo) e URL pública.
  final String? imagePath;
  final String? imageUrl;

  /// Vídeo: link https.
  final String? videoUrl;
  final DateTime createdAt;

  const PortfolioItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.description,
    this.imagePath,
    this.imageUrl,
    this.videoUrl,
  });

  bool get isVideo => type == PortfolioMediaType.video;

  /// Miniatura: a própria foto, ou a capa do vídeo quando é do YouTube.
  String? get thumbnailUrl {
    if (!isVideo) return imageUrl;
    final id = youtubeVideoId(videoUrl);
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  @override
  List<Object?> get props =>
      [id, userId, type, title, description, imagePath, imageUrl, videoUrl, createdAt];
}

/// Extrai o código do vídeo de um link do YouTube (ou `null`).
/// Aceita "youtube.com/watch?v=CODIGO", "youtu.be/CODIGO" e
/// "youtube.com/shorts/CODIGO".
String? youtubeVideoId(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final host = uri.host.replaceFirst('www.', '').replaceFirst('m.', '');

  String? id;
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    id = uri.pathSegments.first;
  } else if (host == 'youtube.com') {
    id = uri.queryParameters['v'];
    if (id == null &&
        uri.pathSegments.length >= 2 &&
        (uri.pathSegments.first == 'shorts' || uri.pathSegments.first == 'embed')) {
      id = uri.pathSegments[1];
    }
  }
  // Os códigos do YouTube têm 11 caracteres: letras, números, "-" e "_".
  return id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
}
