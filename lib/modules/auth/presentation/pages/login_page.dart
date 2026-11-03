// =============================================================================
// modules/auth/presentation/pages/login_page.dart
// -----------------------------------------------------------------------------
// TEL02 — ENTRAR.
//
//   * E-mail e senha obrigatórios; e-mail no formato válido;
//   * TEL02-E1 (credenciais inválidas): banner de erro SEM dizer qual campo
//     está errado — assim ninguém descobre se um e-mail tem conta (RN04);
//   * Sucesso: o SessionCubit percebe o login e o AuthGate abre o app.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_header.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Chave do formulário: permite validar todos os campos de uma vez.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Mensagem do banner de erro (TEL02-E1). `null` = sem banner.
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await getIt<AuthRepository>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      // Sucesso: o AuthGate troca de tela sozinho. Fecha as telas de acesso
      // que estavam empilhadas (Boas-vindas -> Entrar).
      (_) => Navigator.of(context).popUntil((route) => route.isFirst),
    );
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
                const AuthHeader(title: 'Entrar'),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  AppBanner.error(_errorMessage!),
                  const SizedBox(height: 16),
                ],
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
                    validator: Validators.email,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Senha',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
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
                    validator: Validators.password,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => const SignUpPage()),
                          ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
