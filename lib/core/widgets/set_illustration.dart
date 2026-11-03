// =============================================================================
// core/widgets/set_illustration.dart
// -----------------------------------------------------------------------------
// ILUSTRAÇÃO "SET AO ENTARDECER" (sugestão S01 da documentação).
//
//   céu em degradê  ·  facho de luz  ·  sol âmbar  ·  montanhas em camadas
//
// É desenhada em CÓDIGO (CustomPainter), sem arquivo de imagem: fica nítida
// em qualquer tamanho e não usa fotos de pessoas (que seriam dados pessoais).
// Três paletas (azul, roxo, verde-azulado) dão variedade aos cartões; a
// paleta pode ser escolhida pelo nome da pessoa ou do projeto, para que o
// mesmo item tenha sempre a mesma ilustração.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SetPalette {
  navy(Color(0xFF1F4D78), Color(0xFF17324D), Color(0xFF223F5C), Color(0xFF13283D)),
  purple(Color(0xFF6A4A8C), Color(0xFF3B2B57), Color(0xFF4C3A6B), Color(0xFF2E2244)),
  teal(Color(0xFF2A7A78), Color(0xFF184B4E), Color(0xFF1F5E5E), Color(0xFF123B3D));

  /// Céu (topo e base do degradê) e montanhas (fundo e frente).
  final Color skyTop;
  final Color skyBottom;
  final Color mountainBack;
  final Color mountainFront;

  const SetPalette(this.skyTop, this.skyBottom, this.mountainBack, this.mountainFront);

  /// Mesma entrada -> mesma paleta (soma simples dos códigos das letras).
  static SetPalette fromSeed(String seed) {
    final sum = seed.codeUnits.fold<int>(0, (total, code) => total + code);
    return SetPalette.values[sum % SetPalette.values.length];
  }
}

class SetIllustration extends StatelessWidget {
  final SetPalette palette;

  /// Texto para leitores de tela (a imagem é decorativa por padrão).
  final String? semanticLabel;

  const SetIllustration({super.key, this.palette = SetPalette.navy, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final painting = CustomPaint(painter: _SetPainter(palette), size: Size.infinite);
    if (semanticLabel == null) return ExcludeSemantics(child: painting);
    return Semantics(image: true, label: semanticLabel, child: painting);
  }
}

class _SetPainter extends CustomPainter {
  final SetPalette palette;

  _SetPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1) Céu em degradê.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.skyBottom],
        ).createShader(rect),
    );

    // 2) Facho de luz (refletor), um trapézio claro e transparente.
    final beam = Path()
      ..moveTo(w * 0.22, 0)
      ..lineTo(w * 0.34, 0)
      ..lineTo(w * 0.62, h)
      ..lineTo(w * 0.40, h)
      ..close();
    canvas.drawPath(beam, Paint()..color = Colors.white.withValues(alpha: 0.08));

    // 3) Sol âmbar.
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.34),
      h * 0.2,
      Paint()..color = AppColors.accent,
    );

    // 4) Montanhas: camada do fundo e camada da frente.
    final back = Path()
      ..moveTo(0, h * 0.72)
      ..lineTo(w * 0.28, h * 0.50)
      ..lineTo(w * 0.52, h * 0.70)
      ..lineTo(w * 0.80, h * 0.48)
      ..lineTo(w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = palette.mountainBack);

    final front = Path()
      ..moveTo(0, h * 0.86)
      ..lineTo(w * 0.36, h * 0.66)
      ..lineTo(w * 0.66, h * 0.88)
      ..lineTo(w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = palette.mountainFront);
  }

  @override
  bool shouldRepaint(covariant _SetPainter oldDelegate) => oldDelegate.palette != palette;
}
