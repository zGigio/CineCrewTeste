// =============================================================================
// modules/portfolio/presentation/widgets/media_details_dialog.dart
// -----------------------------------------------------------------------------
// JANELA para dar TÍTULO e DESCRIÇÃO a um item do portfólio.
// Para vídeos, pede também o LINK (YouTube, Vimeo, Instagram, Drive...).
// Devolve os textos digitados, ou `null` se o usuário cancelar.
// =============================================================================

import 'package:flutter/material.dart';

import '../../domain/usecases/portfolio_usecases.dart';

/// Resultado da janela (um "record" do Dart 3: vários valores juntos).
typedef MediaDetails = ({String title, String description, String url});

Future<MediaDetails?> showMediaDetailsDialog(BuildContext context, {required bool isVideo}) {
  return showDialog<MediaDetails>(
    context: context,
    builder: (_) => _MediaDetailsDialog(isVideo: isVideo),
  );
}

class _MediaDetailsDialog extends StatefulWidget {
  final bool isVideo;

  const _MediaDetailsDialog({required this.isVideo});

  @override
  State<_MediaDetailsDialog> createState() => _MediaDetailsDialogState();
}

class _MediaDetailsDialogState extends State<_MediaDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      url: _urlController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isVideo ? 'Adicionar vídeo' : 'Sobre esta foto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isVideo) ...[
                TextFormField(
                  controller: _urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Link do vídeo',
                    hintText: 'https://youtu.be/...',
                  ),
                  validator: PortfolioRules.videoUrl,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                autofocus: !widget.isVideo,
                maxLength: PortfolioRules.maxTitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex.: Clipe "Noite Clara" – direção de fotografia',
                ),
                validator: PortfolioRules.title,
              ),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: PortfolioRules.maxDescription,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                validator: PortfolioRules.description,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirm, child: const Text('Adicionar')),
      ],
    );
  }
}
