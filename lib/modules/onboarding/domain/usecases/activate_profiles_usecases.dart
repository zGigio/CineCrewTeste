// =============================================================================
// modules/onboarding/domain/usecases/activate_profiles_usecases.dart
// -----------------------------------------------------------------------------
// CASOS DE USO DE ATIVAÇÃO DOS PERFIS (uma conta, dois modos):
//
//   * ActivateProfessionalProfileUseCase (TEL05 -> TEL08):
//       confere nome, contato, especialidades, aceite e localização;
//       registra o aceite (LGPD) e salva o perfil profissional.
//   * ActivateRecruiterProfileUseCase (TEL09):
//       confere responsável e produtora e ativa o modo Contratar.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../entities/location_terms.dart';
import '../onboarding_validators.dart';

/// Tudo o que foi preenchido nos 4 passos.
class ProfessionalDraft extends Equatable {
  final String name;
  final String contact;

  /// A primeira vira a função principal; as outras, habilidades extras.
  final List<String> specialties;
  final bool acceptedTerms;
  final GeoPlace? place;

  const ProfessionalDraft({
    required this.name,
    required this.contact,
    required this.specialties,
    required this.acceptedTerms,
    required this.place,
  });

  @override
  List<Object?> get props => [name, contact, specialties, acceptedTerms, place];
}

class ActivateProfessionalParams extends Equatable {
  /// Perfil atual (a conta).
  final UserProfile profile;
  final ProfessionalDraft draft;

  const ActivateProfessionalParams({required this.profile, required this.draft});

  @override
  List<Object?> get props => [profile, draft];
}

@injectable
class ActivateProfessionalProfileUseCase
    implements UseCase<UserProfile, ActivateProfessionalParams> {
  final ProfileRepository repository;

  ActivateProfessionalProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(ActivateProfessionalParams params) async {
    final draft = params.draft;
    final error = OnboardingValidators.name(draft.name) ??
        OnboardingValidators.contact(draft.contact) ??
        OnboardingValidators.specialties(draft.specialties);
    if (error != null) return Left(ValidationFailure(error));
    if (!draft.acceptedTerms) {
      return const Left(ValidationFailure('É preciso aceitar o uso da localização.'));
    }
    final place = draft.place;
    if (place == null || !place.isValid) {
      return const Left(ValidationFailure('Defina onde você atua.'));
    }

    // 1) Registra o aceite (com data e versão do texto) no banco.
    final consent = await repository.acceptLocationTerms(LocationTerms.version);
    // `fold` com o tipo explícito: os dois lados devolvem um Future<Either>.
    return consent.fold<Future<Either<Failure, UserProfile>>>(
      (failure) async => Left(failure),
      // 2) Salva o perfil profissional completo.
      (acceptedAt) => repository.updateProfile(
        params.profile.copyWith(
          fullName: draft.name.trim(),
          phone: draft.contact.trim(),
          primaryRole: draft.specialties.first,
          secondarySkills: draft.specialties.skip(1).toList(),
          latitude: place.latitude,
          longitude: place.longitude,
          city: place.city ?? '',
          state: place.state ?? '',
          isProfessional: true,
          locationConsentAt: acceptedAt,
        ),
      ),
    );
  }
}

class ActivateRecruiterParams extends Equatable {
  final UserProfile profile;
  final String responsibleName;
  final String company;

  const ActivateRecruiterParams({
    required this.profile,
    required this.responsibleName,
    required this.company,
  });

  @override
  List<Object?> get props => [profile, responsibleName, company];
}

@injectable
class ActivateRecruiterProfileUseCase implements UseCase<UserProfile, ActivateRecruiterParams> {
  final ProfileRepository repository;

  ActivateRecruiterProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(ActivateRecruiterParams params) async {
    final error = OnboardingValidators.name(params.responsibleName) ??
        OnboardingValidators.company(params.company);
    if (error != null) return Left(ValidationFailure(error));

    return repository.updateProfile(
      params.profile.copyWith(
        fullName: params.responsibleName.trim(),
        companyName: params.company.trim(),
        isRecruiter: true,
      ),
    );
  }
}
