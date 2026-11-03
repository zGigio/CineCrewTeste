// =============================================================================
// modules/auth/presentation/cubit/session_cubit.dart
// -----------------------------------------------------------------------------
// CUBIT DA SESSÃO: controla quem está logado e em qual modo.
//
// Cubit é a versão simplificada do BLoC: em vez de receber "eventos", ele
// tem MÉTODOS (ex.: switchMode) que calculam um novo estado e o EMITEM com
// `emit(...)`. Toda tela que "escuta" o cubit é redesenhada.
//
// Este cubit é GLOBAL (um só para o app inteiro), pois quase todas as telas
// precisam saber quem é o usuário logado.
// =============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'session_state.dart';

/// `@lazySingleton`: uma única instância para o app todo.
@lazySingleton
class SessionCubit extends Cubit<SessionState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  /// "Assinatura" do fluxo de login/logout (guardada para cancelar depois).
  StreamSubscription<String?>? _authSubscription;

  /// Ao ser criado, o cubit começa a ESCUTAR as mudanças de login.
  SessionCubit(this._authRepository, this._profileRepository)
      : super(const SessionState()) {
    _authSubscription = _authRepository.userIdChanges.listen(_onUserChanged);
  }

  /// Chamado sempre que o usuário logado muda.
  Future<void> _onUserChanged(String? userId) async {
    // Ninguém logado -> tela de login.
    if (userId == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }

    // Mesmo usuário já carregado (ex.: só renovou o token) -> nada a fazer.
    if (state.status == SessionStatus.authenticated &&
        state.profile?.id == userId) {
      return;
    }

    // Mostra o carregamento enquanto busca o perfil. Antes ficava a tela
    // de boas-vindas por baixo, e parecia que o login "não tinha entrado".
    if (state.status != SessionStatus.authenticated) {
      emit(const SessionState(status: SessionStatus.unknown));
    }
    await _loadProfile(userId);
  }

  /// "Tentar de novo" da tela de erro: recarrega o perfil do usuário logado.
  Future<void> retry() async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }
    emit(const SessionState(status: SessionStatus.unknown));
    await _loadProfile(userId);
  }

  /// Busca o perfil no banco e entra no app.
  Future<void> _loadProfile(String userId) async {
    final result = await _profileRepository.getProfile(userId);

    // `fold` trata os dois lados do Either: erro (esquerda) ou sucesso (direita).
    result.fold(
      // Falhou: a pessoa CONTINUA logada no Supabase, então não dá para
      // mostrar a tela de boas-vindas (ela tentaria entrar de novo e cairia
      // no mesmo erro). Mostra o motivo, com "Tentar de novo" e "Sair".
      (failure) => emit(
        SessionState(
          status: SessionStatus.loadError,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        SessionState(
          // Conta desativada: só a tela de reativação (TEL02-E2).
          status: profile.isDeactivated
              ? SessionStatus.deactivated
              : SessionStatus.authenticated,
          profile: profile,
          // Ao entrar, abre no ÚLTIMO MODO USADO (P20), se ainda for válido.
          mode: _resolveMode(
            profile,
            state.status == SessionStatus.authenticated
                ? state.mode
                : AppMode.fromValue(profile.lastMode) ?? state.mode,
          ),
        ),
      ),
    );
  }

  /// Recarrega o perfil do banco (ex.: depois de alguma alteração).
  Future<void> refreshProfile() async {
    final userId = state.profile?.id;
    if (userId != null) await _loadProfile(userId);
  }

  /// Atualiza o perfil em memória depois que ele foi salvo pela tela de perfil.
  void updateProfile(UserProfile profile) {
    emit(
      SessionState(
        status: SessionStatus.authenticated,
        profile: profile,
        mode: _resolveMode(profile, state.mode),
      ),
    );
  }

  /// Alterna entre "modo profissional" e "modo contratante".
  /// Só permite ir para um modo se o usuário tiver aquele papel.
  void switchMode(AppMode mode) {
    final profile = state.profile;
    if (profile == null) return;
    if (mode == AppMode.recruiter && !profile.isRecruiter) return;
    if (mode == AppMode.professional && !profile.isProfessional) return;

    emit(
      SessionState(
        status: state.status,
        profile: profile,
        mode: mode,
      ),
    );
    // Guarda o modo para o próximo login (P20). Se falhar, não atrapalha.
    _profileRepository.saveLastMode(profile.id, mode.value);
  }

  /// Sai da conta. O fluxo `userIdChanges` emite `null` e o app volta
  /// sozinho para a tela de login.
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Decide o modo válido para o perfil:
  /// mantém o modo atual se o usuário tiver aquele papel; senão, usa o papel
  /// que ele tem (prioridade para profissional).
  AppMode _resolveMode(UserProfile profile, AppMode current) {
    if (current == AppMode.recruiter && profile.isRecruiter) {
      return AppMode.recruiter;
    }
    if (current == AppMode.professional && profile.isProfessional) {
      return AppMode.professional;
    }
    return profile.isProfessional ? AppMode.professional : AppMode.recruiter;
  }

  /// Ao destruir o cubit, para de escutar o fluxo de login (evita vazamento
  /// de memória).
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
