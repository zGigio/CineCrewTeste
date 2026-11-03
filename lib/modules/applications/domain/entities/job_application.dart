// =============================================================================
// modules/applications/domain/entities/job_application.dart
// -----------------------------------------------------------------------------
// ENTIDADE CANDIDATURA (camada de DOMÍNIO).
//
// Liga um PROFISSIONAL a uma VAGA. O processo seletivo segue um fluxo fixo
// (uma "máquina de estados"):
//
//   pendente ──► aprovado p/ entrevista ──► proposta enviada ──► contratado
//      │                  │                        └──────────► proposta recusada
//      └──► reprovado ◄───┘
//
//   * O CONTRATANTE: aprova p/ entrevista, reprova e envia a proposta.
//   * O PROFISSIONAL: aceita ou recusa a proposta.
//   * Só depois do ACEITE o chat entre os dois é liberado.
// As mesmas regras existem no banco (gatilho validate_application_status).
// =============================================================================

import 'package:equatable/equatable.dart';

import '../../../jobs/domain/entities/job.dart';
import '../../../profile/domain/entities/user_profile.dart';

/// Status da candidatura.
enum ApplicationStatus {
  pending('pendente', 'Em análise'),
  interview('aprovado_entrevista', 'Aprovado para entrevista'),
  rejected('reprovado', 'Não selecionado'),
  offerSent('proposta_enviada', 'Proposta enviada'),
  hired('contratado', 'Contratado'),
  offerDeclined('proposta_recusada', 'Proposta recusada');

  const ApplicationStatus(this.value, this.label);

  /// Valor gravado no banco.
  final String value;

  /// Texto exibido na tela.
  final String label;

  /// Converte o texto do banco no enum (padrão: pendente).
  static ApplicationStatus fromValue(String? value) =>
      ApplicationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ApplicationStatus.pending,
      );

  /// Mudanças que o CONTRATANTE pode fazer a partir deste status.
  List<ApplicationStatus> get recruiterActions => switch (this) {
        ApplicationStatus.pending => const [
            ApplicationStatus.interview,
            ApplicationStatus.rejected,
          ],
        ApplicationStatus.interview => const [
            ApplicationStatus.offerSent,
            ApplicationStatus.rejected,
          ],
        _ => const [],
      };

  /// Mudanças que o PROFISSIONAL pode fazer a partir deste status.
  List<ApplicationStatus> get professionalActions => switch (this) {
        ApplicationStatus.offerSent => const [
            ApplicationStatus.hired,
            ApplicationStatus.offerDeclined,
          ],
        _ => const [],
      };

  /// O contratante pode mudar deste status para [next]?
  bool recruiterCanChangeTo(ApplicationStatus next) => recruiterActions.contains(next);

  /// O profissional pode mudar deste status para [next]?
  bool professionalCanChangeTo(ApplicationStatus next) =>
      professionalActions.contains(next);

  /// Estado final: ninguém pode mudar mais.
  bool get isFinal => recruiterActions.isEmpty && professionalActions.isEmpty;

  /// O chat entre contratante e profissional está liberado?
  bool get chatUnlocked => this == ApplicationStatus.hired;
}

/// Candidatura de um profissional a uma vaga.
class JobApplication extends Equatable {
  final String id;
  final String jobId;
  final String professionalId;

  /// Mensagem de apresentação enviada pelo profissional.
  final String? coverMessage;

  final ApplicationStatus status;
  final DateTime createdAt;

  /// Dados da vaga (preenchidos na visão do PROFISSIONAL).
  final Job? job;

  /// Dados do candidato (preenchidos na visão do CONTRATANTE).
  final UserProfile? professional;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.professionalId,
    this.coverMessage,
    required this.status,
    required this.createdAt,
    this.job,
    this.professional,
  });

  /// Cópia da candidatura com outro status (usado ao atualizar a lista).
  JobApplication withStatus(ApplicationStatus newStatus) => JobApplication(
        id: id,
        jobId: jobId,
        professionalId: professionalId,
        coverMessage: coverMessage,
        status: newStatus,
        createdAt: createdAt,
        job: job,
        professional: professional,
      );

  @override
  List<Object?> get props =>
      [id, jobId, professionalId, coverMessage, status, createdAt, job, professional];
}
