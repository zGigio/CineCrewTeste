// =============================================================================
// modules/payments/presentation/pages/payout_account_page.dart
// -----------------------------------------------------------------------------
// TELA "CONTA PARA RECEBER": para onde vão os saques da carteira.
//
//   Titular ........ nome + CPF/CNPJ (obrigatórios)
//   [x] Pix ........ tipo da chave + chave
//   [x] TED ........ banco + agência + conta + tipo
//
// Pelo menos uma das duas formas precisa estar preenchida. Os dados são
// validados no app (dígitos do CPF/CNPJ, formato da chave...) e de novo no
// banco de dados. Só o próprio usuário consegue ver estes dados (RLS).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/brazilian_banks.dart';
import '../../domain/entities/payout_account.dart';
import '../../domain/payout_validators.dart';
import '../cubit/wallet_cubit.dart';

class PayoutAccountPage extends StatefulWidget {
  const PayoutAccountPage({super.key});

  @override
  State<PayoutAccountPage> createState() => _PayoutAccountPageState();
}

class _PayoutAccountPageState extends State<PayoutAccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _holderNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _agencyController = TextEditingController();
  final _accountController = TextEditingController();

  bool _usePix = true;
  bool _useBank = false;
  PixKeyType _pixKeyType = PixKeyType.cpf;
  String? _bankCode;
  BankAccountType _accountType = BankAccountType.checking;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Preenche com a conta já cadastrada (edição).
    final account = context.read<WalletCubit>().state.account;
    if (account != null) {
      _holderNameController.text = account.holderName;
      _documentController.text = account.holderDocument;
      _usePix = account.hasPix;
      _pixKeyType = account.pixKeyType ?? PixKeyType.cpf;
      _pixKeyController.text = account.pixKey ?? '';
      _useBank = account.hasBankAccount;
      _bankCode = account.bankCode;
      _agencyController.text = account.agency ?? '';
      _accountController.text = account.accountNumber ?? '';
      _accountType = account.accountType ?? BankAccountType.checking;
    }
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _documentController.dispose();
    _pixKeyController.dispose();
    _agencyController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  /// Usa o CPF/CNPJ do titular como chave Pix (atalho comum nos bancos).
  void _useDocumentAsPixKey() {
    final digits = PayoutValidators.onlyDigits(_documentController.text);
    setState(() {
      _pixKeyType = digits.length == 14 ? PixKeyType.cnpj : PixKeyType.cpf;
      _pixKeyController.text = digits;
    });
  }

  Future<void> _save() async {
    if (!_usePix && !_useBank) {
      showAppMessage(context, 'Ative o Pix ou a conta bancária.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final account = PayoutAccount(
      holderName: _holderNameController.text.trim(),
      holderDocument: PayoutValidators.onlyDigits(_documentController.text),
      pixKeyType: _usePix ? _pixKeyType : null,
      pixKey: _usePix
          ? PayoutValidators.normalizePixKey(_pixKeyType, _pixKeyController.text)
          : null,
      bankCode: _useBank ? _bankCode : null,
      bankName: _useBank ? bankByCode(_bankCode)?.name : null,
      agency: _useBank ? _agencyController.text.trim() : null,
      accountNumber: _useBank ? _accountController.text.trim() : null,
      accountType: _useBank ? _accountType : null,
    );

    setState(() => _isSaving = true);
    final error = await context.read<WalletCubit>().saveAccount(account);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      showAppMessage(context, error, isError: true);
    } else {
      showAppMessage(context, 'Conta salva!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conta para receber')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- Titular ----------------------------------------------------
            Text('Titular', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _holderNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: PayoutValidators.holderName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF ou CNPJ',
                helperText: 'Precisa ser o mesmo titular da conta e da chave Pix.',
              ),
              validator: PayoutValidators.document,
            ),
            const SizedBox(height: 16),

            // ----- Pix ----------------------------------------------------------
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.pix),
              title: const Text('Receber via Pix'),
              subtitle: const Text('Saque na hora'),
              value: _usePix,
              onChanged: (value) => setState(() => _usePix = value),
            ),
            if (_usePix) ...[
              DropdownButtonFormField<PixKeyType>(
                // A key muda junto com o tipo: assim o campo se atualiza quando
                // o botão "Usar meu CPF/CNPJ" troca o tipo por código.
                key: ValueKey(_pixKeyType),
                initialValue: _pixKeyType,
                decoration: const InputDecoration(labelText: 'Tipo de chave'),
                items: [
                  for (final type in PixKeyType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (type) => setState(() => _pixKeyType = type!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pixKeyController,
                keyboardType: switch (_pixKeyType) {
                  PixKeyType.email => TextInputType.emailAddress,
                  PixKeyType.phone => TextInputType.phone,
                  PixKeyType.random => TextInputType.text,
                  _ => TextInputType.number,
                },
                decoration: InputDecoration(
                  labelText: 'Chave Pix',
                  hintText: switch (_pixKeyType) {
                    PixKeyType.cpf => '000.000.000-00',
                    PixKeyType.cnpj => '00.000.000/0000-00',
                    PixKeyType.email => 'voce@email.com',
                    PixKeyType.phone => '(21) 99999-8888',
                    PixKeyType.random => '8-4-4-4-12 caracteres',
                  },
                ),
                validator: (value) =>
                    _usePix ? PayoutValidators.pixKey(_pixKeyType, value) : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _useDocumentAsPixKey,
                  child: const Text('Usar meu CPF/CNPJ como chave'),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // ----- TED ----------------------------------------------------------
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.account_balance_outlined),
              title: const Text('Receber via TED'),
              subtitle: const Text('Conta bancária · cai em dias úteis'),
              value: _useBank,
              onChanged: (value) => setState(() => _useBank = value),
            ),
            if (_useBank) ...[
              DropdownButtonFormField<String>(
                initialValue: _bankCode,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Banco'),
                items: [
                  for (final bank in brazilianBanks)
                    DropdownMenuItem(value: bank.code, child: Text(bank.display)),
                ],
                onChanged: (code) => setState(() => _bankCode = code),
                validator: (code) => _useBank && code == null ? 'Escolha o banco.' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _agencyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Agência'),
                      validator: (value) => _useBank ? PayoutValidators.agency(value) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _accountController,
                      decoration: const InputDecoration(
                        labelText: 'Conta com dígito',
                        hintText: '12345-6',
                      ),
                      validator: (value) =>
                          _useBank ? PayoutValidators.accountNumber(value) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<BankAccountType>(
                segments: [
                  for (final type in BankAccountType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_accountType},
                onSelectionChanged: (selection) =>
                    setState(() => _accountType = selection.first),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar conta'),
            ),
            const SizedBox(height: 8),
            Text(
              '🔒 Só você vê estes dados. Nesta versão de demonstração, nenhum '
              'valor real é transferido.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
