// =============================================================================
// modules/portfolio/domain/entities/experience.dart
// -----------------------------------------------------------------------------
// ENTIDADE: EXPERIÊNCIA — um trabalho anterior, como na seção "Experiência"
// do LinkedIn: função, produção/empresa, tipo de projeto e período.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Tipos de projeto audiovisual (os mesmos aceitos pelo banco).
const List<String> experienceCategories = [
  'Filme',
  'Série',
  'Publicidade',
  'Videoclipe',
  'Evento',
  'Casamento',
  'Institucional',
  'Outro',
];

class Experience extends Equatable {
  /// `null` = experiência nova (ainda não gravada).
  final String? id;
  final String role;
  final String production;
  final String? category;

  /// Datas guardadas no dia 1º do mês (só mês e ano importam).
  final DateTime startDate;

  /// `null` = trabalho atual.
  final DateTime? endDate;
  final String? description;

  const Experience({
    this.id,
    required this.role,
    required this.production,
    required this.startDate,
    this.category,
    this.endDate,
    this.description,
  });

  bool get isCurrent => endDate == null;

  /// "mar. 2024 – atual" ou "jan. 2022 – jun. 2023".
  String get periodLabel =>
      '${monthYear(startDate)} – ${endDate == null ? 'atual' : monthYear(endDate!)}';

  /// Duração em texto: "1 ano e 3 meses", "5 meses", "menos de 1 mês".
  String durationLabel({DateTime? now}) {
    final end = endDate ?? now ?? DateTime.now();
    final months = (end.year - startDate.year) * 12 + end.month - startDate.month + 1;
    if (months < 1) return 'menos de 1 mês';
    final years = months ~/ 12;
    final rest = months % 12;
    final parts = [
      if (years > 0) years == 1 ? '1 ano' : '$years anos',
      if (rest > 0) rest == 1 ? '1 mês' : '$rest meses',
    ];
    return parts.join(' e ');
  }

  @override
  List<Object?> get props => [id, role, production, category, startDate, endDate, description];
}

const _monthNames = [
  'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
  'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.',
];

/// "mar. 2024"
String monthYear(DateTime date) => '${_monthNames[date.month - 1]} ${date.year}';
