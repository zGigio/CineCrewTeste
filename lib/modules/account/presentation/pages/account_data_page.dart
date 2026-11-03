// =============================================================================
// modules/account/presentation/pages/account_data_page.dart
// -----------------------------------------------------------------------------
// TEL21 — DADOS DA CONTA (nome, e-mail e senha). Valem para os dois modos.
//
//   * Nome: salvo direto no perfil;
//   * E-mail: o Supabase manda um link de confirmação para o e-mail NOVO; a
//     troca só vale depois de confirmar (o perfil acompanha sozinho);
//   * Senha: só muda se a pessoa tocar em "Alterar senha" e preencher.
// Mesmas validações do cadastro (TEL03).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/account_repository.dart';

class AccountDataPage extends StatefulWidget {
  const AccountDataPage({super.key});

  @override
  State<AccountDataPage> createState() => _AccountDataPageState();
}

class _AccountDataPageState extends State<AccountDataPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _changePassword = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SessionCubit>().state.profile!;
    _nameController = TextEditingController(text: profile.fullName);
    _emailController = TextEditingController(text: profile.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionCubit>();
    final profile = session.state.profile!;
    final account = getIt<AccountRepository>();
    setState(() => _isSaving = true);

    final messages = <String>[];
    String? error;

    // 1) Nome (perfil).
    final name = _nameController.text.trim();
    if (name != profile.fullName) {
      final result = await getIt<ProfileRepository>().updateProfile(
        profile.copyWith(fullName: name),
      );
      error = result.fold<String?>((failure) => failure.message, (saved) {
        session.updateProfile(saved);
        return null;
      });
    }
    // 2) E-mail (login): precisa confirmar pelo link enviado ao e-mail novo.
    final email = _emailController.text.trim();
    if (error == null && email != (profile.email ?? '')) {
      final result = await account.updateEmail(email);
      error = result.fold<String?>((failure) => failure.message, (_) {
        messages.add('Enviamos um link de confirmação para $email.');
        return null;
      });
    }
    // 3) Senha (só se pediu para alterar).
    if (error == null && _changePassword) {
      final result = await account.updatePassword(_passwordController.text);
      error = result.fold<String?>((failure) => failure.message, (_) {
        messages.add('Senha alterada.');
        return null;
      });
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      showAppMessage(context, error, isError: true);
      return;
    }
    showAppMessage(context, messages.isEmpty ? 'Dados salvos!' : messages.join(' '));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dados da conta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    LabeledField(
                      label: 'Nome completo',
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            (value?.trim().length ?? 0) < 2 ? 'Informe seu nome' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'E-mail',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.email)),
                        validator: Validators.email,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Senha',
                      child: _changePassword
                          ? TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofocus: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock),
                                hintText: 'Nova senha: 8+ caracteres, letras e números',
                              ),
                              validator: Validators.newPassword,
                            )
                          : const TextField(
                              enabled: false,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock),
                                hintText: '••••••••',
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _changePassword = !_changePassword),
                        child: Text(_changePassword ? 'Manter a senha atual' : 'Alterar senha'),
                      ),
                    ),
                    Text('Estes dados valem para os dois modos de uso.', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alterações'),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
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
