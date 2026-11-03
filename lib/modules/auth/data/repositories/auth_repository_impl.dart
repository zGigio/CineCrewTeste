// =============================================================================
// modules/auth/data/repositories/auth_repository_impl.dart
// -----------------------------------------------------------------------------
// IMPLEMENTAÇÃO da autenticação usando o SUPABASE AUTH.
//
// O Supabase cuida da parte sensível: guarda as senhas criptografadas,
// gera o token de sessão (JWT) e o renova automaticamente.
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Unit, unit;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_guard.dart';
import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Stream<String?> get userIdChanges =>
      // `onAuthStateChange` avisa: sessão restaurada, login, logout,
      // renovação do token... Aqui só interessa o id do usuário da sessão.
      _client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Either<Failure, Unit>> signIn({
    required String email,
    required String password,
  }) {
    return guardRequest<Unit>(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required bool isProfessional,
    required bool isRecruiter,
  }) {
    return guardRequest<bool>(() async {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        // "metadata": dados extras enviados junto com o cadastro.
        // O gatilho `handle_new_user` (schema.sql) lê esses dados e cria
        // o perfil automaticamente na tabela `profiles`.
        data: {
          'full_name': fullName.trim(),
          'is_professional': isProfessional,
          'is_recruiter': isRecruiter,
        },
      );
      // Sem sessão = o Supabase está esperando a confirmação do e-mail.
      return response.session == null;
    });
  }

  @override
  Future<Either<Failure, Unit>> signOut() {
    return guardRequest<Unit>(() async {
      await _client.auth.signOut();
      return unit;
    });
  }
}
