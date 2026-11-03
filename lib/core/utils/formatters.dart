// =============================================================================
// core/utils/formatters.dart
// -----------------------------------------------------------------------------
// FORMATAÇÃO de datas, valores em reais e distâncias no padrão brasileiro.
//
// Funções simples e "puras" (mesma entrada -> mesma saída, sem efeitos
// colaterais), o que facilita testá-las (ver test/core/formatters_test.dart).
// =============================================================================

/// Funções de formatação usadas nas telas.
class Formatters {
  Formatters._();

  /// Completa com zero à esquerda: 5 -> "05".
  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  /// Data: 07/03/2026
  static String date(DateTime value) =>
      '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';

  /// Hora: 14:05
  static String time(DateTime value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

  /// Data e hora: 07/03/2026 14:05
  static String dateTime(DateTime value) => '${date(value)} ${time(value)}';

  /// Período de um trabalho:
  ///   - mesmo dia:    "07/03/2026, 08:00 às 18:00"
  ///   - dias diferentes: "07/03 08:00 até 09/03 18:00"
  static String period(DateTime start, DateTime end) {
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${date(start)}, ${time(start)} às ${time(end)}';
    }
    final startShort = '${_twoDigits(start.day)}/${_twoDigits(start.month)}';
    final endShort = '${_twoDigits(end.day)}/${_twoDigits(end.month)}';
    return '$startShort ${time(start)} até $endShort ${time(end)}';
  }

  /// Valor em reais: 1500.5 -> "R$ 1.500,50"
  static String currency(double value) {
    // Separa a parte inteira dos centavos (sempre com 2 casas).
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final cents = parts[1];

    // Insere o ponto separador de milhar, de trás para frente.
    final buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      final positionFromEnd = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) buffer.write('.');
    }
    return 'R\$ ${buffer.toString()},$cents';
  }

  /// Lê um valor digitado pelo usuário em reais.
  /// Aceita "1500", "1500,50", "1.500,50" e "1500.50".
  /// Devolve `null` se o texto não for um número válido.
  static double? parseCurrency(String text) {
    var cleaned = text.replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.contains(',')) {
      // Formato brasileiro: ponto = milhar, vírgula = decimal.
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }

  /// Distância: 0.35 -> "350 m" | 7.18 -> "7,2 km"
  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
