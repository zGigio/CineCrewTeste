// =============================================================================
// test/modules/profile/user_profile_model_test.dart
// -----------------------------------------------------------------------------
// TESTES da conversão do perfil (JSON do Supabase <-> objeto Dart).
// Garante que os papéis e os campos opcionais são lidos corretamente.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:audiovisual_app/modules/profile/data/models/user_profile_model.dart';

void main() {
  group('UserProfileModel.fromJson', () {
    test('lê um perfil com os dois papéis e localização', () {
      final profile = UserProfileModel.fromJson({
        'id': 'abc-123',
        'full_name': 'Leonardo Santos',
        'email': 'leo@uva.br',
        'is_professional': true,
        'is_recruiter': true,
        'primary_role': 'Videomaker',
        'secondary_skills': ['Drone', 'Edição'],
        'latitude': -22.9068,
        'longitude': -43.1729,
        'rating': 5, // inteiro no JSON deve virar double
      });

      expect(profile.hasBothRoles, isTrue);
      expect(profile.firstName, 'Leonardo');
      expect(profile.secondarySkills, ['Drone', 'Edição']);
      expect(profile.hasLocation, isTrue);
      expect(profile.rating, 5.0);
    });

    test('usa valores padrão quando os campos vêm nulos', () {
      final profile = UserProfileModel.fromJson({'id': 'xyz'});

      expect(profile.fullName, '');
      expect(profile.isProfessional, isTrue);
      expect(profile.isRecruiter, isFalse);
      expect(profile.secondarySkills, isEmpty);
      expect(profile.hasLocation, isFalse);
      expect(profile.hasResume, isFalse);
    });
  });

  group('UserProfileModel.toUpdateJson', () {
    test('converte textos vazios em null', () {
      final profile = UserProfileModel.fromJson({
        'id': 'abc',
        'full_name': '  Ana  ',
      }).copyWith(phone: '   ', bio: '');

      final json = UserProfileModel.toUpdateJson(profile);

      expect(json['full_name'], 'Ana');
      expect(json['phone'], isNull);
      expect(json['bio'], isNull);
      // Campos que o usuário não pode alterar não vão no JSON.
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('rating'), isFalse);
    });
  });
}
