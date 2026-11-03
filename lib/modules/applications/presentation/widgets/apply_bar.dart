// =============================================================================
// modules/applications/presentation/widgets/apply_bar.dart
// -----------------------------------------------------------------------------
// BARRA "CANDIDATAR-SE" exibida no rodapé do detalhe da vaga.
//
// Ao abrir, verifica se o usuário já se candidatou:
//   - se SIM: mostra o status atual da candidatura;
//   - se NÃO: mostra o botão "Candidatar-se", que abre uma janela para
//     escrever a mensagem de apresentação.
// Não aparece para quem está no modo contratante nem para o dono da vaga.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/application_repository.dart';
import '../../domain/usecases/apply_to_job_usecase.dart';
import 'application_status_chip.dart';

class ApplyBar extends StatefulWidget {
  final Job job;

  const ApplyBar({super.key, required this.job});

  @override
  State<ApplyBar> createState() => _ApplyBarState();
}

class _ApplyBarState extends State<ApplyBar> {
  /// Candidatura existente (nula se ainda não se candidatou).
  JobApplication? _application;

  /// Verificando se já existe candidatura?
  bool _isChecking = true;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  /// O usuário pode se candidatar a esta vaga?
  bool get _canApply {
    final session = context.read<SessionCubit>().state;
    final profile = session.profile;
    return profile != null &&
        !session.isRecruiterMode &&
        profile.isProfessional &&
        widget.job.recruiterId != profile.id;
  }

  /// Procura a candidatura do usuário nesta vaga.
  Future<void> _checkExisting() async {
    final profile = context.read<SessionCubit>().state.profile;
    if (profile == null || !_canApply) {
      // Atribuição direta (sem setState): este trecho roda dentro do
      // initState, antes da primeira construção da tela.
      _isChecking = false;
      return;
    }
    final result = await getIt<ApplicationRepository>().findApplication(
      jobId: widget.job.id,
      professionalId: profile.id,
    );
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _application = result.getOrElse((_) => null);
    });
  }

  /// Abre a janela da mensagem e envia a candidatura.
  Future<void> _apply() async {
    final message = await _askCoverMessage();
    if (message == null || !mounted) return; // cancelou

    final profile = context.read<SessionCubit>().state.profile!;
    setState(() => _isSending = true);
    final result = await getIt<ApplyToJobUseCase>()(
      ApplyParams(job: widget.job, applicant: profile, coverMessage: message),
    );
    if (!mounted) return;
    setState(() => _isSending = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (application) {
        setState(() => _application = application);
        showAppMessage(context, 'Candidatura enviada! O contratante foi avisado.');
      },
    );
  }

  /// Janela para escrever a apresentação. Devolve o texto ou `null`.
  Future<String?> _askCoverMessage() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Candidatar-se'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: ApplyToJobUseCase.maxMessageLength,
          decoration: const InputDecoration(
            hintText: 'Conte por que você é a pessoa certa para esta vaga '
                '(experiência, equipamentos, disponibilidade...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Enviar candidatura'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Não mostra nada para quem não pode se candidatar.
    if (!_canApply) return const SizedBox.shrink();

    final Widget content;
    if (_isChecking) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_application != null) {
      // Já se candidatou: mostra o status.
      content = Row(
        children: [
          const Text('Sua candidatura: '),
          ApplicationStatusChip(status: _application!.status),
        ],
      );
    } else if (!widget.job.isOpen) {
      content = const Text('Esta vaga foi encerrada.');
    } else {
      content = FilledButton.icon(
        onPressed: _isSending ? null : _apply,
        icon: _isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: const Text('Candidatar-se'),
      );
    }

    // Rodapé com sombra, acima da área de gestos do celular (SafeArea).
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}
