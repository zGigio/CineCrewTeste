// =============================================================================
// modules/profile/data/repositories/profile_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO do repositório de perfis usando o SUPABASE.
//
//   * Dados do perfil      -> tabela `profiles` (PostgreSQL)
//   * Foto de perfil       -> bucket `avatars` (pasta pública do Storage)
//   * Currículo em PDF     -> bucket `resumes` (pasta privada do Storage)
//
// Toda chamada passa pelo `guardRequest`, que transforma erros técnicos em
// Failures com mensagens em português.
// =============================================================================

import 'dart:typed_data';

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_profile_model.dart';
import '../profile_columns.dart';

/// Registrado no GetIt: quem pedir [ProfileRepository] recebe esta classe.
@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  /// Nome da tabela e das pastas no Supabase.
  static const String _table = 'profiles';
  static const String _avatarBucket = 'avatars';
  static const String _resumeBucket = 'resumes';
  static const String _portfolioBucket = 'portfolio';

  /// Validade do link temporário do currículo: 1 hora (em segundos).
  static const int _resumeLinkSeconds = 60 * 60;

  /// Cliente do Supabase recebido por injeção de dependência.
  final SupabaseClient _client;

  ProfileRepositoryImpl(this._client);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) {
    return guardRequest<UserProfile>(() async {
      final isOwn = userId == _client.auth.currentUser?.id;
      var row = await _selectProfile(userId);

      // Conta SEM linha em `profiles` (ex.: criada antes do gatilho
      // handle_new_user existir, ou com o gatilho falhando): cria agora pela
      // função do banco e lê de novo. Só vale para o próprio usuário.
      if (row == null && isOwn) {
        await _client.rpc('ensure_my_profile');
        row = await _selectProfile(userId);
      }
      if (row == null) throw const ServerFailure(message: 'Perfil não encontrado.');
      final profile = UserProfileModel.fromJson(row);

      // Perfil de OUTRA pessoa: só os dados públicos (posição aproximada).
      if (!isOwn) return profile;

      // Perfil PRÓPRIO: busca também a coordenada exata e o aceite (LGPD),
      // que só o dono pode ler (funções do banco).
      return _withPrivateData(profile);
    });
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) {
    return guardRequest<UserProfile>(() async {
      // UPDATE profiles SET ... WHERE id = profile.id
      // `.select().single()` devolve a linha já atualizada.
      final row = await _client
          .from(_table)
          .update(UserProfileModel.toUpdateJson(profile))
          .eq('id', profile.id)
          .select(ProfileColumns.public)
          .single();
      // A coordenada exata e o aceite não voltam no SELECT (são privados):
      // reaproveitamos os valores que acabaram de ser salvos.
      return UserProfileModel.fromJson(row).copyWith(
        latitude: profile.latitude,
        longitude: profile.longitude,
        locationConsentAt: profile.locationConsentAt,
      );
    });
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) {
    return guardRequest<String>(() async {
      // Cada usuário só pode gravar dentro da pasta com o próprio id
      // (regra definida no schema.sql). Ex.: "<id>/avatar.jpg".
      final path = '$userId/avatar.jpg';

      // `upsert: true`: se já existir uma foto, ela é substituída.
      await _client.storage.from(_avatarBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      // Monta a URL pública da foto. O "?v=..." muda a cada envio para o
      // app não mostrar a foto antiga guardada em cache.
      final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);
      final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await _client.from(_table).update({'avatar_url': url}).eq('id', userId);
      return url;
    });
  }

  @override
  Future<Either<Failure, String>> uploadCover({
    required String userId,
    required Uint8List bytes,
  }) {
    return guardRequest<String>(() async {
      // A capa fica na pasta pública "portfolio": "<id>/capa.jpg".
      final path = '$userId/capa.jpg';
      await _client.storage.from(_portfolioBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
      final publicUrl = _client.storage.from(_portfolioBucket).getPublicUrl(path);
      final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await _client.from(_table).update({'cover_url': url}).eq('id', userId);
      return url;
    });
  }

  @override
  Future<Either<Failure, String>> uploadResume({
    required String userId,
    required Uint8List bytes,
  }) {
    return guardRequest<String>(() async {
      final path = '$userId/curriculo.pdf';

      await _client.storage.from(_resumeBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
          );

      await _client.from(_table).update({'resume_path': path}).eq('id', userId);
      return path;
    });
  }

  @override
  Future<Either<Failure, Unit>> saveLastMode(String userId, String mode) {
    return guardRequest<Unit>(() async {
      await _client.from(_table).update({'last_mode': mode}).eq('id', userId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, DateTime>> acceptLocationTerms(String termsVersion) {
    return guardRequest<DateTime>(() async {
      final acceptedAt = await _client.rpc(
        'accept_location_terms',
        params: {'p_version': termsVersion},
      );
      return DateTime.parse(acceptedAt as String).toLocal();
    });
  }

  /// `SELECT (colunas públicas) FROM profiles WHERE id = userId`
  /// (`maybeSingle`: devolve null, em vez de erro, se não houver linha).
  Future<Map<String, dynamic>?> _selectProfile(String userId) => _client
      .from(_table)
      .select(ProfileColumns.public)
      .eq('id', userId)
      .maybeSingle();

  /// Completa o perfil PRÓPRIO com os dados privados.
  Future<UserProfile> _withPrivateData(UserProfile profile) async {
    // As duas chamadas começam juntas (mais rápido).
    final locationFuture = _client.rpc('get_my_location');
    final consentFuture = _client.rpc('get_my_location_consent');
    final locationRows = await locationFuture as List<dynamic>;
    final consent = await consentFuture as String?;

    final location = locationRows.isEmpty
        ? const <String, dynamic>{}
        : locationRows.first as Map<String, dynamic>;
    return profile.copyWith(
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
      locationConsentAt: consent == null ? null : DateTime.parse(consent).toLocal(),
    );
  }

  @override
  Future<Either<Failure, String>> getResumeUrl(String resumePath) {
    // "Signed URL": link assinado que só funciona por um tempo limitado.
    return guardRequest<String>(
      () => _client.storage
          .from(_resumeBucket)
          .createSignedUrl(resumePath, _resumeLinkSeconds),
    );
  }
}
