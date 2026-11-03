// =============================================================================
// core/theme/app_theme.dart
// -----------------------------------------------------------------------------
// TEMA VISUAL CineCrew (claro), conforme o design system da documentação:
//
//   * Cores: azul-marinho (primária) + âmbar (destaque) — ver app_colors.dart;
//   * Tipografia: Roboto (padrão do Android)
//       Título grande 28/34 · Título de tela 22/28 negrito ·
//       Título de seção 16 negrito · Corpo 14/20 · Apoio 13 · Legenda 12;
//   * Espaçamento: grade de 4 dp, margem lateral de 16 dp;
//   * Raios: campos 8 · botões 10 · cartões 14 · chips "pílula" · diálogos 16;
//   * Botões com 48 dp de altura (área de toque mínima recomendada).
//
// Centralizar o tema aqui garante que todas as telas tenham a mesma
// identidade: trocar uma cor neste arquivo muda o app inteiro.
// =============================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Atalho mantido por compatibilidade: cor de destaque (âmbar).
  /// Usada em elementos gráficos (mapa, botão de busca), nunca em texto.
  static const Color accentColor = AppColors.accent;

  // ---- Raios (documentação: seção 3.3) --------------------------------------
  static const double radiusField = 8;
  static const double radiusButton = 10;
  static const double radiusCard = 14;
  static const double radiusDialog = 16;

  /// Raio padrão de imagens e mapas.
  static const double radius = 12;

  /// Margem lateral padrão das telas.
  static const double screenPadding = 16;

  /// Estilo do botão de DESTAQUE (âmbar), para a ação principal de busca ou
  /// criação. Uso: `FilledButton(style: AppTheme.highlightButton, ...)`.
  static final ButtonStyle highlightButton = FilledButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.text, // texto escuro sobre âmbar (7.7:1)
  );

  /// Estilo do botão DESTRUTIVO (vermelho), para excluir e afins.
  static final ButtonStyle destructiveButton = FilledButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
  );

  /// Monta o tema claro do aplicativo.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.text,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.supportBackground,
      surfaceContainer: AppColors.supportBackground,
      surfaceContainerHigh: AppColors.supportBackground,
      surfaceContainerHighest: AppColors.primarySoft,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: Colors.white,
    );

    // Tipografia da documentação (tamanho / altura da linha).
    const textTheme = TextTheme(
      headlineMedium: TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 22 / 16),
      bodyMedium: TextStyle(fontSize: 14, height: 20 / 14),
      bodySmall: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(fontSize: 12, height: 16 / 12),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    );
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      // `apply` pinta todos os textos com a cor principal; depois devolvemos
      // a cor secundária ao texto de apoio (bodySmall).
      textTheme: textTheme
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
          .copyWith(bodySmall: textTheme.bodySmall),

      // Barra superior branca com divisória fina embaixo.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),

      // Cartões: brancos, raio 14 e sombra suave (1 dp).
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x33000000),
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),

      // Botões: 48 dp de altura, texto 15 negrito, raio 10.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.primary,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),

      // Botão flutuante em "pílula" (ex.: "Mapa" / "Lista").
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),

      // Campos: fundo branco, borda cinza, foco azul-marinho, erro vermelho.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: fieldBorder(AppColors.border),
        enabledBorder: fieldBorder(AppColors.border),
        focusedBorder: fieldBorder(AppColors.primary, 2),
        errorBorder: fieldBorder(AppColors.error),
        focusedErrorBorder: fieldBorder(AppColors.error, 2),
        errorStyle: const TextStyle(color: AppColors.error),
      ),

      // Chips "pílula": selecionado = azul-marinho com texto branco e ✓.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.text, fontSize: 14),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // Interruptor: verde quando ligado (como nas pranchas).
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.success : null,
        ),
      ),

      // Barra inferior: branca, indicador azul bem claro.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusDialog)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusDialog)),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
