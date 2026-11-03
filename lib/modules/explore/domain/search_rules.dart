// =============================================================================
// modules/explore/domain/search_rules.dart
// -----------------------------------------------------------------------------
// VALIDAÇÃO DA BUSCA (TEL11-E1): devolve um mapa campo -> mensagem, para a
// tela mostrar cada erro embaixo do campo certo. Mapa vazio = tudo certo.
// =============================================================================

import '../../../core/constants/audiovisual_roles.dart';
import 'entities/search_criteria.dart';

enum SearchField { place, specialties, radius, projectName }

class SearchRules {
  SearchRules._();

  static Map<SearchField, String> validate(SearchCriteria criteria) {
    final errors = <SearchField, String>{};
    final place = criteria.place;
    if (place == null || !place.isValid) {
      errors[SearchField.place] = 'Defina o local do projeto';
    }
    if (criteria.specialties.isEmpty) {
      errors[SearchField.specialties] = 'Selecione ao menos uma especialidade';
    } else if (criteria.specialties.any((s) => !audiovisualRoles.contains(s))) {
      errors[SearchField.specialties] = 'Use apenas especialidades do catálogo';
    }
    final radiusError = radius(criteria.radiusKm);
    if (radiusError != null) errors[SearchField.radius] = radiusError;
    final name = criteria.projectName?.trim() ?? '';
    if (name.length > 80) errors[SearchField.projectName] = 'Nome muito longo (máx. 80).';
    return errors;
  }

  /// Raio: inteiro entre 1 e 200 km (P05).
  static String? radius(int? km) {
    if (km == null || km <= 0) return 'Informe um raio maior que zero';
    if (km < RadiusRules.min || km > RadiusRules.max) {
      return 'Use um raio entre ${RadiusRules.min} e ${RadiusRules.max} km';
    }
    return null;
  }
}
