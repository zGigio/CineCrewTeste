// =============================================================================
// modules/portfolio/domain/repositories/portfolio_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do portfólio e das experiências de um usuário.
// =============================================================================

import 'dart:typed_data';

import 'package:fpdart/fpdart.dart' show Either, Unit;

import '../../../../core/error/failures.dart';
import '../entities/experience.dart';
import '../entities/portfolio_item.dart';

abstract class PortfolioRepository {
  /// Itens do portfólio (mais recentes primeiro).
  Future<Either<Failure, List<PortfolioItem>>> getItems(String userId);

  /// Envia a foto para o Storage e cria o item.
  Future<Either<Failure, PortfolioItem>> addPhoto({
    required String userId,
    required Uint8List bytes,
    required String title,
    String? description,
  });

  /// Cria um item de vídeo (só o link).
  Future<Either<Failure, PortfolioItem>> addVideo({
    required String userId,
    required String url,
    required String title,
    String? description,
  });

  /// Apaga o item (e o arquivo da foto, se houver).
  Future<Either<Failure, Unit>> deleteItem(PortfolioItem item);

  /// Experiências (atuais primeiro, depois das mais recentes às mais antigas).
  Future<Either<Failure, List<Experience>>> getExperiences(String userId);

  /// Cria (sem id) ou atualiza (com id) uma experiência.
  Future<Either<Failure, Experience>> saveExperience(String userId, Experience experience);

  Future<Either<Failure, Unit>> deleteExperience(String experienceId);
}
