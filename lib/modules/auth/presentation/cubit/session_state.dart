// =============================================================================
// modules/auth/presentation/cubit/session_state.dart
// -----------------------------------------------------------------------------
// ESTADO DA SESSÃO do usuário.
//
// No padrão BLoC/Cubit, a tela não guarda dados de negócio: ela apenas
// "desenha" o ESTADO atual. Quando o estado muda (ex.: o usuário fez login),
// as telas que dependem dele são redesenhadas automaticamente.
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../../profile/domain/entities/user_profile.dart';

/// Situação da sessão.
enum SessionStatus {
  /// Ainda verificando se há alguém logado (app acabou de abrir).
  unknown,

  /// Ninguém logado: mostrar a tela de login.
  unauthenticated,

  /// Usuário logado e perfil carregado: mostrar o app.
  authenticated,

  /// Logado, mas a conta está DESATIVADA: só pode reativar ou sair
  /// (TEL02-E2; decisão para a pendência P01).
  deactivated,

  /// Logado no Supabase, mas o PERFIL não pôde ser carregado (ex.: banco
  /// desatualizado, sem internet). Mostra o erro com "Tentar de novo" e
  /// "Sair", em vez de voltar em silêncio para a tela de boas-vindas.
  loadError,
}

/// Modo de uso atual (como "modo hóspede" e "modo anfitrião" do Airbnb).
/// Quem tem os dois papéis pode alternar entre eles.
enum AppMode {
  professional('Profissional', 'professional'),
  recruiter('Contratar', 'recruiter');

  const AppMode(this.label, this.value);

  /// Nome exibido na tela.
  final String label;

  /// Texto gravado no banco (coluna profiles.last_mode).
  final String value;

  static AppMode? fromValue(String? value) =>
      AppMode.values.where((mode) => mode.value == value).firstOrNull;
}

/// Estado imutável da sessão.
class SessionState extends Equatable {
  final SessionStatus status;

  /// Perfil do usuário logado (nulo quando ninguém está logado).
  final UserProfile? profile;

  /// Modo de uso escolhido (profissional ou contratante).
  final AppMode mode;

  /// Mensagem de erro, se algo falhar ao carregar a sessão.
  final String? errorMessage;

  const SessionState({
    this.status = SessionStatus.unknown,
    this.profile,
    this.mode = AppMode.professional,
    this.errorMessage,
  });

  /// Atalho: está no modo contratante?
  bool get isRecruiterMode => mode == AppMode.recruiter;

  @override
  List<Object?> get props => [status, profile, mode, errorMessage];
}
