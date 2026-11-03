// =============================================================================
// core/theme/app_colors.dart
// -----------------------------------------------------------------------------
// PALETA DO DESIGN SYSTEM CineCrew (documentação visual, seção 3).
//
// Cada cor tem um PAPEL. O contraste de cada par (cor de fundo x texto) foi
// conferido na documentação; todos passam de 4.5:1 (nível AA de acessib.).
//
//   Papel              Cor       Texto por cima   Contraste
//   Primária           #17324D   #FFFFFF          13.1:1
//   Primária escura    #0F2236   #FFFFFF          16.1:1
//   Destaque (âmbar)   #E8A33D   #1B1F24           7.7:1
//   Texto              #1B1F24   (sobre #FFFFFF)  16.6:1
//   Texto secundário   #5B6670   (sobre #FFFFFF)   5.9:1
//   Sucesso            #2E7D32   #FFFFFF           5.1:1
//   Erro               #C62828   #FFFFFF           5.6:1
//   Alerta             #8A5300   (sobre #FFF4E0)   6.3:1
//   Informação         #1565C0   #FFFFFF           5.7:1
// =============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Barras ativas, botão primário, títulos.
  static const Color primary = Color(0xFF17324D);

  /// Botão flutuante, legendas sobre escuro.
  static const Color primaryDark = Color(0xFF0F2236);

  /// Ação principal de busca e criação ("Buscar profissionais", "Criar conta").
  /// Atenção: âmbar NÃO é cor de texto sobre branco (contraste baixo).
  static const Color accent = Color(0xFFE8A33D);

  /// Fundo das telas e dos cartões.
  static const Color surface = Color(0xFFFFFFFF);

  /// Áreas secundárias (fundo de apoio, campos desabilitados).
  static const Color supportBackground = Color(0xFFF4F6F8);

  /// Texto principal.
  static const Color text = Color(0xFF1B1F24);

  /// Legendas e textos de apoio.
  static const Color textSecondary = Color(0xFF5B6670);

  /// Campos, cartões e divisórias.
  static const Color border = Color(0xFFD5DBE1);

  // ---- Cores de estado (com o fundo claro usado nos banners) ---------------
  static const Color success = Color(0xFF2E7D32);
  static const Color successBackground = Color(0xFFE8F5E9);

  static const Color error = Color(0xFFC62828);
  static const Color errorBackground = Color(0xFFFDECEC);

  static const Color warning = Color(0xFF8A5300);
  static const Color warningBackground = Color(0xFFFFF4E0);

  static const Color info = Color(0xFF1565C0);
  static const Color infoBackground = Color(0xFFE8F0FB);

  /// Fundo suave do item selecionado (barra inferior, avatar com iniciais).
  static const Color primarySoft = Color(0xFFDCE6F0);
}
