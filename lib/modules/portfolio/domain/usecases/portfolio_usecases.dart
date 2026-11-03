// =============================================================================
// modules/portfolio/domain/usecases/portfolio_usecases.dart
// -----------------------------------------------------------------------------
// CASOS DE USO do perfil estilo LinkedIn (com validação antes do servidor):
//   * AddPortfolioPhotoUseCase -> título + foto (até 8 MB);
//   * AddPortfolioVideoUseCase -> título + link https de vídeo;
//   * SaveExperienceUseCase    -> função, produção e período coerente.
// O limite de 30 itens é conferido pelo banco.
// =============================================================================

import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/experience.dart';
import '../entities/portfolio_item.dart';
import '../repositories/portfolio_repository.dart';

/// Regras de tamanho compartilhadas pelos formulários e casos de uso.
class PortfolioRules {
  PortfolioRules._();

  static const int maxTitle = 80;
  static const int maxDescription = 500;
  static const int maxPhotoBytes = 8 * 1024 * 1024; // 8 MB

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Dê um título ao trabalho.';
    if (text.length > maxTitle) return 'Título muito longo (máx. $maxTitle).';
    return null;
  }

  static String? description(String? value) =>
      (value?.trim().length ?? 0) > maxDescription
          ? 'Descrição muito longa (máx. $maxDescription).'
          : null;

  /// Link de vídeo: precisa ser um endereço https válido.
  static String? videoUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Cole o link completo do vídeo (começando com https://).';
    }
    return null;
  }

  static String? _orNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class AddPhotoParams extends Equatable {
  final String userId;
  final Uint8List bytes;
  final String title;
  final String? description;

  const AddPhotoParams({
    required this.userId,
    required this.bytes,
    required this.title,
    this.description,
  });

  @override
  List<Object?> get props => [userId, bytes.length, title, description];
}

@injectable
class AddPortfolioPhotoUseCase implements UseCase<PortfolioItem, AddPhotoParams> {
  final PortfolioRepository repository;

  AddPortfolioPhotoUseCase(this.repository);

  @override
  Future<Either<Failure, PortfolioItem>> call(AddPhotoParams params) async {
    final error = PortfolioRules.title(params.title) ??
        PortfolioRules.description(params.description);
    if (error != null) return Left(ValidationFailure(error));
    if (params.bytes.isEmpty) return const Left(ValidationFailure('Escolha uma foto.'));
    if (params.bytes.length > PortfolioRules.maxPhotoBytes) {
      return const Left(ValidationFailure('A foto deve ter no máximo 8 MB.'));
    }
    return repository.addPhoto(
      userId: params.userId,
      bytes: params.bytes,
      title: params.title.trim(),
      description: PortfolioRules._orNull(params.description),
    );
  }
}

class AddVideoParams extends Equatable {
  final String userId;
  final String url;
  final String title;
  final String? description;

  const AddVideoParams({
    required this.userId,
    required this.url,
    required this.title,
    this.description,
  });

  @override
  List<Object?> get props => [userId, url, title, description];
}

@injectable
class AddPortfolioVideoUseCase implements UseCase<PortfolioItem, AddVideoParams> {
  final PortfolioRepository repository;

  AddPortfolioVideoUseCase(this.repository);

  @override
  Future<Either<Failure, PortfolioItem>> call(AddVideoParams params) async {
    final error = PortfolioRules.title(params.title) ??
        PortfolioRules.videoUrl(params.url) ??
        PortfolioRules.description(params.description);
    if (error != null) return Left(ValidationFailure(error));
    return repository.addVideo(
      userId: params.userId,
      url: params.url.trim(),
      title: params.title.trim(),
      description: PortfolioRules._orNull(params.description),
    );
  }
}

class SaveExperienceParams extends Equatable {
  final String userId;
  final Experience experience;

  const SaveExperienceParams({required this.userId, required this.experience});

  @override
  List<Object?> get props => [userId, experience];
}

@injectable
class SaveExperienceUseCase implements UseCase<Experience, SaveExperienceParams> {
  final PortfolioRepository repository;

  SaveExperienceUseCase(this.repository);

  @override
  Future<Either<Failure, Experience>> call(SaveExperienceParams params) async {
    final experience = params.experience;
    final role = experience.role.trim();
    final production = experience.production.trim();

    if (role.length < 2 || role.length > 80) {
      return const Left(ValidationFailure('Informe a sua função (2 a 80 caracteres).'));
    }
    if (production.length < 2 || production.length > 120) {
      return const Left(ValidationFailure('Informe a produção ou empresa (2 a 120 caracteres).'));
    }
    if (experience.startDate.year < 1950) {
      return const Left(ValidationFailure('Data de início inválida.'));
    }
    final end = experience.endDate;
    if (end != null && end.isBefore(experience.startDate)) {
      return const Left(ValidationFailure('O fim não pode ser antes do início.'));
    }
    final descriptionError = PortfolioRules.description(experience.description);
    if (descriptionError != null) return Left(ValidationFailure(descriptionError));

    return repository.saveExperience(
      params.userId,
      Experience(
        id: experience.id,
        role: role,
        production: production,
        category: experience.category,
        startDate: experience.startDate,
        endDate: end,
        description: PortfolioRules._orNull(experience.description),
      ),
    );
  }
}
