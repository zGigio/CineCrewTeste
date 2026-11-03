// =============================================================================
// modules/talent_search/data/datasources/talent_remote_data_source.dart
// -----------------------------------------------------------------------------
// DATA SOURCE REMOTO (camada de DADOS).
//
// É a classe que efetivamente conversa com o BACK-END (Supabase).
// A busca por raio é feita DENTRO do banco, pela função SQL
// `search_professionals` (arquivo supabase/schema.sql), que usa o PostGIS.
// O app apenas chama essa função via "RPC" (Remote Procedure Call =
// "chamada de procedimento remoto") e recebe a lista pronta, já ordenada
// pela distância. Se algo falhar, LANÇA uma [ServerException].
// =============================================================================

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, SupabaseClient;

import '../../../../core/error/exceptions.dart';
import '../models/professional_model.dart';

/// Contrato do Data Source remoto.
abstract class TalentRemoteDataSource {
  /// Busca profissionais dentro do raio informado.
  /// Lança [ServerException] em caso de erro.
  Future<List<ProfessionalModel>> searchByRadius({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? skill,
  });

  /// Busca o perfil de um profissional pelo [id].
  /// Lança [ServerException] em caso de erro.
  Future<ProfessionalModel> getTalentById(String id);
}

/// Implementação usando o cliente do Supabase.
@LazySingleton(as: TalentRemoteDataSource)
class TalentRemoteDataSourceImpl implements TalentRemoteDataSource {
  /// Cliente do Supabase injetado (configurado em register_module.dart).
  final SupabaseClient client;

  TalentRemoteDataSourceImpl(this.client);

  @override
  Future<List<ProfessionalModel>> searchByRadius({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? skill,
  }) async {
    try {
      // Chama a função SQL `search_professionals`. Os nomes dos parâmetros
      // (p_lat, p_lng...) precisam ser IGUAIS aos declarados no SQL.
      final response = await client.rpc(
        'search_professionals',
        params: {
          'p_lat': latitude,
          'p_lng': longitude,
          'p_radius_km': radiusInKm,
          'p_skill': (skill != null && skill.isNotEmpty) ? skill : null,
        },
      );

      // A função devolve uma LISTA de linhas (cada linha é um Map/JSON).
      final rows = response as List<dynamic>;
      return rows
          .map((row) => ProfessionalModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (_) {
      throw const ServerException(message: 'Erro ao processar dados de resposta.');
    }
  }

  @override
  Future<ProfessionalModel> getTalentById(String id) async {
    try {
      // SELECT na tabela `profiles`. Como o JSON do perfil usa `full_name`
      // e o modelo espera `name`, renomeamos na própria consulta com
      // "name:full_name" (apelido de coluna do PostgREST).
      final row = await client
          .from('profiles')
          .select(
            'id, name:full_name, email, phone, primary_role, secondary_skills, '
            // Só a posição APROXIMADA: a exata é protegida pelo banco.
            'bio, avatar_url, city, state, latitude:approx_latitude, '
            'longitude:approx_longitude, rating, is_available',
          )
          .eq('id', id)
          .single();
      return ProfessionalModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (_) {
      throw const ServerException(
        message: 'Erro ao buscar perfil do profissional.',
      );
    }
  }
}
