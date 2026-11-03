// =============================================================================
// core/widgets/app_banner.dart
// -----------------------------------------------------------------------------
// BANNER DE MENSAGEM do design system (seção 3.5 da documentação):
//
//   [!] Erro: falha ou dado inválido.            (vermelho)
//   [✓] Sucesso: ação concluída.                 (verde)
//   [!] Alerta: ação pendente ou limitação.      (âmbar escuro)
//   [i] Informação: contexto adicional.          (azul)
//
// Cor nunca é a única pista: cada tipo tem também um ÍCONE próprio, e o
// leitor de tela anuncia o tipo antes do texto (acessibilidade).
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BannerType { error, success, warning, info }

class AppBanner extends StatelessWidget {
  final BannerType type;
  final String message;

  const AppBanner({super.key, required this.type, required this.message});

  const AppBanner.error(this.message, {super.key}) : type = BannerType.error;
  const AppBanner.warning(this.message, {super.key}) : type = BannerType.warning;
  const AppBanner.info(this.message, {super.key}) : type = BannerType.info;
  const AppBanner.success(this.message, {super.key}) : type = BannerType.success;

  @override
  Widget build(BuildContext context) {
    // "Record" do Dart 3: devolve várias informações de uma vez.
    final (Color foreground, Color background, IconData icon, String spokenType) =
        switch (type) {
      BannerType.error => (AppColors.error, AppColors.errorBackground, Icons.warning_rounded, 'Erro'),
      BannerType.success => (AppColors.success, AppColors.successBackground, Icons.check_rounded, 'Sucesso'),
      BannerType.warning => (AppColors.warning, AppColors.warningBackground, Icons.warning_rounded, 'Alerta'),
      BannerType.info => (AppColors.info, AppColors.infoBackground, Icons.info_rounded, 'Informação'),
    };

    return Semantics(
      container: true,
      liveRegion: true, // o leitor de tela anuncia quando o banner aparece
      label: '$spokenType: $message',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground, fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
