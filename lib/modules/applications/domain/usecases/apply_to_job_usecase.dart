// =============================================================================
// modules/applications/domain/usecases/apply_to_job_usecase.dart
// -----------------------------------------------------------------------------
// CASO DE USO: CANDIDATAR-SE A UMA VAGA.
//
// Regras de negócio:
//   1. só quem tem o papel de PROFISSIONAL pode se candidatar;
//   2. ninguém se candidata à PRÓPRIA vaga;
//   3. a vaga precisa estar ABERTA;
//   4. o perfil precisa ter a FUNÇÃO PRINCIPAL preenchida
//      (o contratante precisa saber o que a pessoa faz);
//   5. a mensagem de apresentação tem no máximo 1000 caracteres.
// O banco (RLS) repete as regras 1 a 3, como segunda camada de segurança.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../entities/job_application.dart';
import '../repositories/application_repository.dart';

/// Dados de entrada da candidatura.
class ApplyParams extends Equatable {
  final Job job;
  final UserProfile applicant;
  final String? coverMessage;

  const ApplyParams({required this.job, required this.applicant, this.coverMessage});

  @override
  List<Object?> get props => [job, applicant, coverMessage];
}

@injectable
class ApplyToJobUseCase implements UseCase<JobApplication, ApplyParams> {
  static const int maxMessageLength = 1000;

  final ApplicationRepository repository;

  ApplyToJobUseCase(this.repository);

  @override
  Future<Either<Failure, JobApplication>> call(ApplyParams params) async {
    final applicant = params.applicant;
    final job = params.job;

    if (!applicant.isProfessional) {
      return const Left(
        ValidationFailure('Ative o papel de profissional no seu perfil para se candidatar.'),
      );
    }
    if (job.recruiterId == applicant.id) {
      return const Left(ValidationFailure('Você não pode se candidatar à sua própria vaga.'));
    }
    if (!job.isOpen) {
      return const Left(ValidationFailure('Esta vaga não está mais aberta.'));
    }
    if (applicant.primaryRole == null || applicant.primaryRole!.trim().isEmpty) {
      return const Left(
        ValidationFailure('Complete seu perfil (função principal) antes de se candidatar.'),
      );
    }

    final message = params.coverMessage?.trim();
    if (message != null && message.length > maxMessageLength) {
      return const Left(
        ValidationFailure('A mensagem deve ter no máximo $maxMessageLength caracteres.'),
      );
    }

    return repository.apply(
      jobId: job.id,
      professionalId: applicant.id,
      coverMessage: (message == null || message.isEmpty) ? null : message,
    );
  }
}
