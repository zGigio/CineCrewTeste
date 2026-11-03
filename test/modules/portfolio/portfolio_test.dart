// =============================================================================
// test/modules/portfolio/portfolio_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 9: perfil estilo LinkedIn.
//   * links do YouTube -> código do vídeo e miniatura;
//   * período e duração das experiências ("mar. 2024 – atual", "1 ano e 2 meses");
//   * validações dos casos de uso (sem chamar o servidor);
//   * conversão das experiências de/para JSON.
// Rodar com: flutter test
// =============================================================================

import 'dart:typed_data';

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/modules/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:audiovisual_app/modules/portfolio/domain/entities/experience.dart';
import 'package:audiovisual_app/modules/portfolio/domain/entities/portfolio_item.dart';
import 'package:audiovisual_app/modules/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:audiovisual_app/modules/portfolio/domain/usecases/portfolio_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Right, Unit, unit;

/// Repositório FALSO: conta as chamadas e devolve o que recebeu.
class FakePortfolioRepository implements PortfolioRepository {
  int calls = 0;
  Experience? savedExperience;

  PortfolioItem _item(PortfolioMediaType type, String title, {String? url}) => PortfolioItem(
        id: 'i1',
        userId: 'u1',
        type: type,
        title: title,
        videoUrl: url,
        createdAt: DateTime(2026, 10, 18),
      );

  @override
  Future<Either<Failure, List<PortfolioItem>>> getItems(String userId) async => const Right([]);

  @override
  Future<Either<Failure, PortfolioItem>> addPhoto({
    required String userId,
    required Uint8List bytes,
    required String title,
    String? description,
  }) async {
    calls++;
    return Right(_item(PortfolioMediaType.photo, title));
  }

  @override
  Future<Either<Failure, PortfolioItem>> addVideo({
    required String userId,
    required String url,
    required String title,
    String? description,
  }) async {
    calls++;
    return Right(_item(PortfolioMediaType.video, title, url: url));
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(PortfolioItem item) async => const Right(unit);

  @override
  Future<Either<Failure, List<Experience>>> getExperiences(String userId) async =>
      const Right([]);

  @override
  Future<Either<Failure, Experience>> saveExperience(String userId, Experience experience) async {
    calls++;
    savedExperience = experience;
    return Right(experience);
  }

  @override
  Future<Either<Failure, Unit>> deleteExperience(String experienceId) async => const Right(unit);
}

void main() {
  group('Links do YouTube', () {
    test('reconhece os formatos comuns', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(youtubeVideoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(youtubeVideoId('https://youtube.com/shorts/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(youtubeVideoId('https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=10'), 'dQw4w9WgXcQ');
    });

    test('outros sites não têm código', () {
      expect(youtubeVideoId('https://vimeo.com/123456'), isNull);
      expect(youtubeVideoId('texto qualquer'), isNull);
    });

    test('miniatura do vídeo do YouTube', () {
      final item = PortfolioItem(
        id: 'i',
        userId: 'u',
        type: PortfolioMediaType.video,
        title: 'Clipe',
        videoUrl: 'https://youtu.be/dQw4w9WgXcQ',
        createdAt: DateTime(2026),
      );
      expect(item.thumbnailUrl, 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
    });
  });

  group('Experiência', () {
    test('período e duração de um trabalho encerrado', () {
      final experience = Experience(
        role: 'Gaffer',
        production: 'Curta "Maré Alta"',
        startDate: DateTime(2023, 1),
        endDate: DateTime(2024, 2),
      );
      expect(experience.periodLabel, 'jan. 2023 – fev. 2024');
      expect(experience.durationLabel(), '1 ano e 2 meses');
    });

    test('trabalho atual', () {
      final experience = Experience(
        role: 'Videomaker',
        production: 'Produtora XYZ',
        startDate: DateTime(2026, 3),
      );
      expect(experience.isCurrent, isTrue);
      expect(experience.periodLabel, 'mar. 2026 – atual');
      expect(experience.durationLabel(now: DateTime(2026, 10, 18)), '8 meses');
    });
  });

  group('Casos de uso', () {
    late FakePortfolioRepository repository;

    setUp(() => repository = FakePortfolioRepository());

    test('vídeo sem https é recusado', () async {
      final result = await AddPortfolioVideoUseCase(repository)(
        const AddVideoParams(userId: 'u', url: 'youtu.be/abc', title: 'Clipe'),
      );
      expect(result.isLeft(), isTrue);
      expect(repository.calls, 0);
    });

    test('foto sem título é recusada', () async {
      final result = await AddPortfolioPhotoUseCase(repository)(
        AddPhotoParams(userId: 'u', bytes: Uint8List.fromList([1, 2, 3]), title: '  '),
      );
      expect(result.isLeft(), isTrue);
    });

    test('foto válida é enviada', () async {
      final result = await AddPortfolioPhotoUseCase(repository)(
        AddPhotoParams(userId: 'u', bytes: Uint8List.fromList([1, 2, 3]), title: 'Bastidores'),
      );
      expect(result.isRight(), isTrue);
      expect(repository.calls, 1);
    });

    test('experiência com fim antes do início é recusada', () async {
      final result = await SaveExperienceUseCase(repository)(
        SaveExperienceParams(
          userId: 'u',
          experience: Experience(
            role: 'Gaffer',
            production: 'Filme',
            startDate: DateTime(2024, 5),
            endDate: DateTime(2024, 1),
          ),
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('experiência é salva com espaços removidos e descrição vazia nula', () async {
      await SaveExperienceUseCase(repository)(
        SaveExperienceParams(
          userId: 'u',
          experience: Experience(
            role: '  Gaffer ',
            production: ' Filme X ',
            startDate: DateTime(2024, 5),
            description: '   ',
          ),
        ),
      );
      expect(repository.savedExperience?.role, 'Gaffer');
      expect(repository.savedExperience?.production, 'Filme X');
      expect(repository.savedExperience?.description, isNull);
    });
  });

  test('experiência -> JSON -> experiência', () {
    final json = PortfolioRepositoryImpl.experienceToJson(
      'u1',
      Experience(role: 'Gaffer', production: 'Filme', startDate: DateTime(2024, 3)),
    );
    expect(json['start_date'], '2024-03-01');
    expect(json['end_date'], isNull);

    final back = PortfolioRepositoryImpl.experienceFromJson({...json, 'id': 'e1'});
    expect(back.startDate, DateTime(2024, 3));
    expect(back.isCurrent, isTrue);
  });
}
