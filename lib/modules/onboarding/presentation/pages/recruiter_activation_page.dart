// =============================================================================
// modules/onboarding/presentation/pages/recruiter_activation_page.dart
// -----------------------------------------------------------------------------
// TEL09 — DADOS DA PRODUTORA (ativa o modo Contratar na mesma conta).
//
//   Nome do responsável (já vem preenchido com o nome da conta)
//   Produtora
//   [ Ativar modo Contratar ]   Agora não
//
// CNPJ não é exigido nesta versão (decisão L10 da documentação).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../domain/onboarding_validators.dart';
import '../../domain/usecases/activate_profiles_usecases.dart';

class RecruiterActivationPage extends StatefulWidget {
  /// `true` = editar os dados da produtora (modo Contratar já ativo),
  /// aberto pela tela Conta (TEL20).
  final bool editing;

  const RecruiterActivationPage({super.key, this.editing = false});

  @override
  State<RecruiterActivationPage> createState() => _RecruiterActivationPageState();
}

class _RecruiterActivationPageState extends State<RecruiterActivationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SessionCubit>().state.profile!;
    _nameController = TextEditingController(text: profile.fullName);
    _companyController = TextEditingController(text: profile.companyName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionCubit>();
    setState(() => _isSaving = true);
    final result = await getIt<ActivateRecruiterProfileUseCase>()(
      ActivateRecruiterParams(
        profile: session.state.profile!,
        responsibleName: _nameController.text,
        company: _companyController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (saved) {
        session.updateProfile(saved);
        if (widget.editing) {
          showAppMessage(context, 'Dados da produtora salvos!');
          Navigator.of(context).pop();
          return;
        }
        session.switchMode(AppMode.recruiter);
        showAppMessage(context, 'Modo Contratar ativo!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.editing ? 'Dados da produtora' : 'Modo Contratar')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.editing ? 'Quem contrata' : 'Ative o modo Contratar',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Informe os dados de quem contrata. Seus dados de conta já foram preenchidos.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Nome do responsável',
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: OnboardingValidators.name,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Produtora',
                      child: TextFormField(
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Nome da produtora'),
                        validator: OnboardingValidators.company,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('CNPJ não é exigido nesta versão.', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isSaving ? null : _activate,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.editing ? 'Salvar alterações' : 'Ativar modo Contratar'),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
                      child: Text(widget.editing ? 'Cancelar' : 'Agora não'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
