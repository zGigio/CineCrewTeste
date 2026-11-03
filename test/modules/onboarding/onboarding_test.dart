// =============================================================================
// test/modules/onboarding/onboarding_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 11: ativação dos perfis e localização.
//   * validações (nome, contato, especialidades do catálogo, produtora);
//   * coordenada válida (nunca (0, 0)) e leitura de CEP;
//   * conversão do resultado do Nominatim (cidade e sigla do estado);
//   * casos de uso: o aceite é registrado ANTES de salvar o perfil, e nada
//     é salvo sem aceite ou sem localização.
// Rodar com: flutter test
// =============================================================================

import 'dart:typed_data';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/core/services/geocoding/geo_place.dart';
import 'package:audiovisual_app/core/services/geocoding/geocoding_service.dart';
import 'package:audiovisual_app/modules/onboarding/domain/entities/location_terms.dart';
import 'package:audiovisual_app/modules/onboarding/domain/onboarding_validators.dart';
import 'package:audiovisual_app/modules/onboarding/domain/usecases/activate_profiles_usecases.dart';
import 'package:audiovisual_app/modules/profile/domain/entities/user_profile.dart';
import 'package:audiovisual_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Right, Unit, unit;

/// Repositório FALSO: registra a ordem das chamadas.
class FakeProfileRepository implements ProfileRepository {
  final calls = <String>[];
  String? acceptedVersion;
  UserProfile? saved;

  @override
  Future<Either<Failure, DateTime>> acceptLocationTerms(String termsVersion) async {
    calls.add('aceite');
    acceptedVersion = termsVersion;
    return Right(DateTime(2026, 10, 18, 10));
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async {
    calls.add('salvar');
    saved = profile;
    return Right(profile);
  }

  @override
  Future<Either<Failure, Unit>> saveLastMode(String userId, String mode) async =>
      const Right(unit);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> uploadCover({
    required String userId,
    required Uint8List bytes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> uploadResume({
    required String userId,
    required Uint8List bytes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> getResumeUrl(String resumePath) async =>
      throw UnimplementedError();
}

/// Conta recém-criada, ainda sem perfil ativo.
const account = UserProfile(
  id: 'u1',
  fullName: 'Leonardo Fontes',
  isProfessional: false,
  isRecruiter: false,
);

const place = GeoPlace(
  latitude: -22.9035,
  longitude: -43.2096,
  label: 'Centro · Rio de Janeiro · RJ',
  city: 'Rio de Janeiro',
  state: 'RJ',
);

ProfessionalDraft draft({bool accepted = true, GeoPlace? at = place}) => ProfessionalDraft(
      name: 'Leonardo Fontes',
      contact: '(21) 99999-8888',
      specialties: const ['Diretor(a) de Fotografia', 'Operador(a) de Câmera'],
      acceptedTerms: accepted,
      place: at,
    );

void main() {
  group('Validações', () {
    test('contato precisa de DDD + número', () {
      expect(OnboardingValidators.contact('(21) 99999-8888'), isNull);
      expect(OnboardingValidators.contact('99999-8888'), isNotNull);
      expect(OnboardingValidators.contact(''), isNotNull);
    });

    test('especialidades: ao menos uma e só do catálogo', () {
      expect(OnboardingValidators.specialties(const []), isNotNull);
      expect(OnboardingValidators.specialties(const ['Videomaker']), isNull);
      expect(OnboardingValidators.specialties(const ['Astronauta']), isNotNull);
    });

    test('coordenada (0, 0) e fora da faixa são inválidas', () {
      expect(place.isValid, isTrue);
      expect(const GeoPlace(latitude: 0, longitude: 0, label: 'x').isValid, isFalse);
      expect(const GeoPlace(latitude: 95, longitude: 10, label: 'x').isValid, isFalse);
    });
  });

  group('Geocodificação (funções sem internet)', () {
    test('reconhece CEP com ou sem hífen', () {
      expect(GeocodingServiceImpl.onlyCep('20040-020'), '20040020');
      expect(GeocodingServiceImpl.onlyCep('20040020'), '20040020');
      expect(GeocodingServiceImpl.onlyCep('Rua Exemplo, 100'), isNull);
    });

    test('converte o resultado do Nominatim com a sigla do estado', () {
      final converted = GeocodingServiceImpl.placeFromNominatim({
        'lat': '-9.3891',
        'lon': '-40.5030',
        'address': {'road': 'Avenida Exemplo', 'city': 'Petrolina', 'state': 'Pernambuco'},
      });
      expect(converted.city, 'Petrolina');
      expect(converted.state, 'PE');
      expect(converted.label, 'Avenida Exemplo · Petrolina · PE');
      expect(converted.isValid, isTrue);
    });
  });

  group('Ativar perfil profissional', () {
    test('registra o aceite ANTES de salvar e grava tudo', () async {
      final repository = FakeProfileRepository();
      final result = await ActivateProfessionalProfileUseCase(repository)(
        ActivateProfessionalParams(profile: account, draft: draft()),
      );

      expect(result.isRight(), isTrue);
      expect(repository.calls, ['aceite', 'salvar']);
      expect(repository.acceptedVersion, LocationTerms.version);
      final saved = repository.saved!;
      expect(saved.isProfessional, isTrue);
      expect(saved.primaryRole, 'Diretor(a) de Fotografia');
      expect(saved.secondarySkills, ['Operador(a) de Câmera']);
      expect(saved.latitude, place.latitude);
      expect(saved.state, 'RJ');
      expect(saved.hasLocationConsent, isTrue);
    });

    test('sem aceite, nada é gravado', () async {
      final repository = FakeProfileRepository();
      final result = await ActivateProfessionalProfileUseCase(repository)(
        ActivateProfessionalParams(profile: account, draft: draft(accepted: false)),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('sem localização, nada é gravado', () async {
      final repository = FakeProfileRepository();
      final result = await ActivateProfessionalProfileUseCase(repository)(
        ActivateProfessionalParams(profile: account, draft: draft(at: null)),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });
  });

  group('Ativar modo Contratar (TEL09)', () {
    test('exige o nome da produtora', () async {
      final repository = FakeProfileRepository();
      final result = await ActivateRecruiterProfileUseCase(repository)(
        const ActivateRecruiterParams(profile: account, responsibleName: 'Leo', company: ''),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('ativa o papel de contratante', () async {
      final repository = FakeProfileRepository();
      await ActivateRecruiterProfileUseCase(repository)(
        const ActivateRecruiterParams(
          profile: account,
          responsibleName: 'Leonardo Fontes',
          company: 'Produtora Horizonte',
        ),
      );
      expect(repository.saved?.isRecruiter, isTrue);
      expect(repository.saved?.companyName, 'Produtora Horizonte');
    });
  });
}
