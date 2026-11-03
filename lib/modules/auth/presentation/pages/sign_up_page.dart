// =============================================================================
// modules/auth/presentation/pages/sign_up_page.dart
// -----------------------------------------------------------------------------
// TEL03 — CRIAR CONTA.
//
// Cria só a CONTA (nome, e-mail e senha). Os perfis — profissional e/ou
// contratante — são ativados DEPOIS, na tela "Como você quer começar?"
// (TEL04). É o modelo "uma conta, dois modos" da documentação (P17).
//
// TEL03-E1: erros aparecem embaixo de cada campo, inclusive
// "Este e-mail já está cadastrado", que vem do servidor.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_header.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Erro do servidor ligado ao campo de e-mail (ex.: já cadastrado).
  String? _emailServerError;

  /// Outros erros do servidor (ex.: sem internet), mostrados em banner.
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailServerError = null;
      _generalError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await getIt<AuthRepository>().signUp(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      // Nenhum perfil ainda: a pessoa escolhe em seguida (TEL04).
      isProfessional: false,
      isRecruiter: false,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final needsEmailConfirmation = result.fold<bool?>(
      (failure) {
        if (failure.message.contains('já está cadastrado')) {
          // Erro de um campo específico: aparece embaixo do e-mail.
          _emailServerError = 'Este e-mail já está cadastrado';
          _formKey.currentState!.validate();
        } else {
          setState(() => _generalError = failure.message);
        }
        return null;
      },
      (value) => value,
    );
    if (needsEmailConfirmation == null) return;

    if (needsEmailConfirmation) {
      // O Supabase enviou um link de confirmação: avisa e leva ao login.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirme seu e-mail'),
          content: const Text(
            'Enviamos um link de confirmação para o seu e-mail. '
            'Depois de confirmar, é só entrar.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }
    // Volta para a raiz: o AuthGate mostra a próxima tela (TEL04 ou login).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Crie sua conta',
                  subtitle: 'Uma única conta serve para contratar e para ser encontrado. '
                      'Você escolhe o modo a seguir.',
                ),
                const SizedBox(height: 16),
                if (_generalError != null) ...[
                  AppBanner.error(_generalError!),
                  const SizedBox(height: 16),
                ],
                LabeledField(
                  label: 'Nome completo',
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(hintText: 'Como você se chama'),
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'nome@exemplo.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    // Se o servidor recusou o e-mail, mostra o motivo aqui.
                    validator: (value) => Validators.email(value) ?? _emailServerError,
                    onChanged: (_) => _emailServerError = null,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Senha',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '8 ou mais caracteres, com letras e números',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.newPassword,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar conta'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                          ),
                  child: const Text('Já tenho conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
