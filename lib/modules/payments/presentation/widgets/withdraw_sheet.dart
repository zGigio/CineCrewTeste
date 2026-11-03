// =============================================================================
// modules/payments/presentation/widgets/withdraw_sheet.dart
// -----------------------------------------------------------------------------
// JANELA DE SAQUE (aberta de baixo para cima).
//   * valor (com atalho "Sacar tudo");
//   * forma: Pix (na hora) ou TED (dias úteis) — só as cadastradas ficam ativas;
//   * botão "Sacar". Devolve `true` se o saque deu certo.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/wallet.dart';
import '../cubit/wallet_cubit.dart';

Future<bool> showWithdrawSheet(BuildContext context, {required WalletCubit cubit}) async {
  final success = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // sobe junto com o teclado
    showDragHandle: true,
    builder: (_) => _WithdrawSheet(cubit: cubit),
  );
  return success ?? false;
}

class _WithdrawSheet extends StatefulWidget {
  final WalletCubit cubit;

  const _WithdrawSheet({required this.cubit});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountController = TextEditingController();
  late WithdrawalMethod _method;
  bool _isSending = false;
  String? _error;

  WalletState get _wallet => widget.cubit.state;

  @override
  void initState() {
    super.initState();
    // Começa no Pix se houver chave cadastrada; senão, TED.
    _method = (_wallet.account?.hasPix ?? false) ? WithdrawalMethod.pix : WithdrawalMethod.ted;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _isAvailable(WithdrawalMethod method) => method == WithdrawalMethod.pix
      ? _wallet.account?.hasPix ?? false
      : _wallet.account?.hasBankAccount ?? false;

  Future<void> _submit() async {
    final amount = Formatters.parseCurrency(_amountController.text);
    if (amount == null) {
      setState(() => _error = 'Digite um valor (ex.: 150,00).');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    final error = await widget.cubit.withdraw(amount, _method);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = _wallet.account;

    return Padding(
      // Empurra o conteúdo para cima quando o teclado abre.
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sacar', style: theme.textTheme.titleLarge),
          Text('Disponível: ${Formatters.currency(_wallet.balance)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              errorText: _error,
              suffixIcon: TextButton(
                onPressed: () => _amountController.text =
                    Formatters.currency(_wallet.balance).replaceAll('R\$ ', ''),
                child: const Text('Tudo'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final method in WithdrawalMethod.values)
            // Opção selecionável (formas não cadastradas ficam desativadas).
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _isAvailable(method),
              onTap: () => setState(() => _method = method),
              leading: Icon(
                method == _method ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: method == _method && _isAvailable(method)
                    ? theme.colorScheme.primary
                    : null,
              ),
              title: Text('${method.label} · ${method.deadline}'),
              subtitle: Text(
                method == WithdrawalMethod.pix
                    ? account?.pixSummary ?? 'Nenhuma chave Pix cadastrada'
                    : account?.bankSummary ?? 'Nenhuma conta bancária cadastrada',
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSending ? null : _submit,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sacar (simulado)'),
          ),
        ],
      ),
    );
  }
}
