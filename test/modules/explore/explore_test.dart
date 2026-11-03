// =============================================================================
// test/modules/explore/explore_test.dart
// -----------------------------------------------------------------------------
// Testes da Parte 12: modo Contratar.
//   * validação da busca por campo (TEL11-E1) e faixa do raio (P05);
//   * textos da pílula de resumo e da distância aproximada;
//   * casos de uso não chamam o servidor com dados inválidos;
//   * cubit dos resultados: sucesso, vazio (TEL12-E2) e erro (TEL12-E3);
//   * conversão do JSON da busca e dos projetos.
// Rodar com: flutter test
// =============================================================================

import 'package:audiovisual_app/core/error/failures.dart';
import 'package:audiovisual_app/core/services/geocoding/geo_place.dart';
import 'package:audiovisual_app/modules/explore/data/repositories/explore_repository_impl.dart';
import 'package:audiovisual_app/modules/explore/domain/entities/project.dart';
import 'package:audiovisual_app/modules/explore/domain/entities/search_criteria.dart';
import 'package:audiovisual_app/modules/explore/domain/entities/talent_result.dart';
import 'package:audiovisual_app/modules/explore/domain/repositories/explore_repository.dart';
import 'package:audiovisual_app/modules/explore/domain/search_rules.dart';
import 'package:audiovisual_app/modules/explore/domain/usecases/explore_usecases.dart';
import 'package:audiovisual_app/modules/explore/presentation/cubit/talent_results_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Right, Unit, unit;

const petrolina = GeoPlace(
  latitude: -9.3891,
  longitude: -40.5030,
  label: 'Centro · Petrolina · PE',
  city: 'Petrolina',
  state: 'PE',
);

const validCriteria = SearchCriteria(
  place: petrolina,
  specialties: ['Diretor(a) de Fotografia', 'Gaffer / Eletricista'],
  radiusKm: 50,
);

const marina = TalentResult(
  id: 'm1',
  name: 'Marina Duarte',
  primaryRole: 'Diretor(a) de Fotografia',
  approxLatitude: -9.33,
  approxLongitude: -40.47,
  distanceKm: 9,
);

/// Repositório FALSO: devolve a lista configurada ou uma falha.
class FakeExploreRepository implements ExploreRepository {
  List<TalentResult> results = const [marina];
  Failure? failure;
  int searchCalls = 0;

  @override
  Future<Either<Failure, List<TalentResult>>> searchTalents(SearchCriteria criteria) async {
    searchCalls++;
    final error = failure;
    return error != null ? Left(error) : Right(results);
  }

  @override
  Future<Either<Failure, List<Project>>> getProjects() async => const Right([]);

  @override
  Future<Either<Failure, Project>> saveProject(Project project) async => Right(project);

  @override
  Future<Either<Failure, Unit>> deleteProject(String projectId) async => const Right(unit);
}

void main() {
  group('Validação da busca (TEL11-E1)', () {
    test('busca vazia: erro em local, especialidade e raio', () {
      final errors = SearchRules.validate(const SearchCriteria(radiusKm: 0));
      expect(errors.keys, containsAll([SearchField.place, SearchField.specialties, SearchField.radius]));
      expect(errors[SearchField.radius], 'Informe um raio maior que zero');
    });

    test('raio entre 1 e 200 km (P05)', () {
      expect(SearchRules.radius(1), isNull);
      expect(SearchRules.radius(200), isNull);
      expect(SearchRules.radius(201), isNotNull);
    });

    test('busca completa é válida', () {
      expect(SearchRules.validate(validCriteria), isEmpty);
    });
  });

  test('textos da pílula e da distância', () {
    expect(validCriteria.placeLabel, 'Petrolina · PE');
    expect(validCriteria.summary, 'Raio 50 km · 2 especialidades');
    expect(marina.distanceLabel, '≈ 9 km do set');
  });

  test('projeto vira critérios de busca', () {
    const project = Project(
      id: 'p1',
      name: 'Longa "Horizonte Seco"',
      place: petrolina,
      radiusKm: 50,
      specialties: ['Gaffer / Eletricista'],
    );
    final criteria = project.toCriteria();
    expect(criteria.projectId, 'p1');
    expect(criteria.radiusKm, 50);
    expect(project.subtitle, 'Petrolina · PE · raio 50 km');
  });

  group('Casos de uso', () {
    test('busca inválida não chega ao servidor', () async {
      final repository = FakeExploreRepository();
      final result = await SearchTalentsUseCase(repository)(const SearchCriteria());
      expect(result.isLeft(), isTrue);
      expect(repository.searchCalls, 0);
    });

    test('projeto sem nome é recusado', () async {
      final result = await SaveProjectUseCase(FakeExploreRepository())(
        const Project(name: '  ', place: petrolina, radiusKm: 50, specialties: ['Videomaker']),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('Cubit dos resultados', () {
    test('sucesso: lista e o mais próximo já selecionado', () async {
      final cubit = TalentResultsCubit(SearchTalentsUseCase(FakeExploreRepository()));
      await cubit.search(validCriteria);
      expect(cubit.state.status, ResultsStatus.success);
      expect(cubit.state.selected, marina);
      await cubit.close();
    });

    test('nenhum profissional (TEL12-E2)', () async {
      final repository = FakeExploreRepository()..results = const [];
      final cubit = TalentResultsCubit(SearchTalentsUseCase(repository));
      await cubit.search(validCriteria);
      expect(cubit.state.isEmpty, isTrue);
      await cubit.close();
    });

    test('erro de conexão mantém a busca (TEL12-E3)', () async {
      final repository = FakeExploreRepository()
        ..failure = const ServerFailure(message: 'Sem conexão');
      final cubit = TalentResultsCubit(SearchTalentsUseCase(repository));
      await cubit.search(validCriteria);
      expect(cubit.state.status, ResultsStatus.failure);
      expect(cubit.state.criteria, validCriteria);

      repository.failure = null; // a internet voltou
      await cubit.retry();
      expect(cubit.state.status, ResultsStatus.success);
      await cubit.close();
    });
  });

  test('converte o JSON da busca (posição aproximada)', () {
    final talent = ExploreRepositoryImpl.talentFromJson({
      'id': 'm1',
      'name': 'Marina Duarte',
      'primary_role': 'Diretor(a) de Fotografia',
      'secondary_skills': ['Operador(a) de Câmera'],
      'latitude': -9.33,
      'longitude': -40.47,
      'distance_in_km': 9,
      'is_available': true,
    });
    expect(talent.specialties, ['Diretor(a) de Fotografia', 'Operador(a) de Câmera']);
    expect(talent.distanceKm, 9);
  });
}
