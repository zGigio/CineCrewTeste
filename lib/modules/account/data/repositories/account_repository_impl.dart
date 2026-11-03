// =============================================================================
// modules/account/data/repositories/account_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO DA CONTA usando o SUPABASE:
//   * e-mail e senha -> Supabase Auth (`updateUser`);
//   * aceite, desativar, reativar e excluir -> funções seguras do banco.
//
// Na exclusão, os ARQUIVOS são apagados primeiro, pela API do Storage
// (o banco não apaga arquivos sozinho): foto, currículo, capa e portfólio.
// Depois, `delete_my_account` apaga a conta e tudo o que depende dela.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, UserAttributes;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/repositories/account_repository.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  final SupabaseClient _client;

  AccountRepositoryImpl(this._client);

  @override
  Future<Either<Failure, Unit>> updateEmail(String email) {
    return guardRequest<Unit>(() async {
      await _client.auth.updateUser(UserAttributes(email: email.trim()));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) {
    return guardRequest<Unit>(() async {
      await _client.auth.updateUser(UserAttributes(password: password));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> revokeLocationConsent() => _rpc('revoke_location_consent');

  @override
  Future<Either<Failure, Unit>> deactivateAccount() => _rpc('deactivate_my_account');

  @override
  Future<Either<Failure, Unit>> reactivateAccount() => _rpc('reactivate_my_account');

  @override
  Future<Either<Failure, Unit>> deleteAccount(String userId) {
    return guardRequest<Unit>(() async {
      // 1) Arquivos de cada pasta do usuário.
      await _removeFolder('avatars', userId);
      await _removeFolder('resumes', userId);
      await _removeFolder('portfolio', userId);
      await _removeFolder('portfolio', '$userId/itens');
      // 2) A conta (e, em cascata, o perfil e os dados).
      await _client.rpc('delete_my_account');
      // 3) A sessão deixou de valer: encerra no aparelho também.
      await _client.auth.signOut();
      return unit;
    });
  }

  /// Apaga todos os ARQUIVOS de uma pasta do Storage (subpastas ficam
  /// de fora: elas aparecem na lista sem `id`).
  Future<void> _removeFolder(String bucket, String folder) async {
    final entries = await _client.storage.from(bucket).list(path: folder);
    final paths = [
      for (final entry in entries)
        if (entry.id != null) '$folder/${entry.name}',
    ];
    if (paths.isNotEmpty) await _client.storage.from(bucket).remove(paths);
  }

  Future<Either<Failure, Unit>> _rpc(String function) {
    return guardRequest<Unit>(() async {
      await _client.rpc(function);
      return unit;
    });
  }
}
