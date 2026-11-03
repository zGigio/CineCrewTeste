// =============================================================================
// modules/payments/presentation/pages/wallet_page.dart
// -----------------------------------------------------------------------------
// TELA "MINHA CARTEIRA" (profissional).
//
//   ┌──────────────────────────────┐
//   │ Saldo disponível             │
//   │ R$ 1.500,00       [ Sacar ]  │
//   └──────────────────────────────┘
//   Conta para receber: Pix ••••.com / Itaú · Ag. 0001 ...   [Editar]
//   Extrato: + pagamentos recebidos / - saques
//
// Tudo SIMULADO: o saque registra a operação, mas nenhum dinheiro é enviado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/wallet.dart';
import '../cubit/wallet_cubit.dart';
import '../widgets/withdraw_sheet.dart';
import 'payout_account_page.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;
    return BlocProvider(
      create: (_) => getIt<WalletCubit>()..open(userId),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  /// Abre o cadastro/edição da conta para receber.
  Future<void> _editAccount(BuildContext context) async {
    final cubit = context.read<WalletCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        // BlocProvider.value: a tela de cadastro usa o MESMO cubit da carteira.
        builder: (_) => BlocProvider.value(value: cubit, child: const PayoutAccountPage()),
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WalletState state) async {
    if (state.account == null) {
      showAppMessage(context, 'Cadastre sua conta para receber antes de sacar.', isError: true);
      await _editAccount(context);
      return;
    }
    final cubit = context.read<WalletCubit>();
    final success = await showWithdrawSheet(context, cubit: cubit);
    if (success && context.mounted) {
      showAppMessage(context, 'Saque realizado! (simulação: nenhum valor real foi enviado)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Minha carteira')),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final account = state.account;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ----- Saldo ----------------------------------------------------
              Card(
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo disponível',
                              style: TextStyle(color: theme.colorScheme.onPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(state.balance),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: state.balance > 0 ? () => _withdraw(context, state) : null,
                        child: const Text('Sacar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simulação para o TCC: os saques são registrados, mas nenhum '
                'dinheiro real é transferido.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // ----- Conta para receber ---------------------------------------
              Text('Conta para receber', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(account == null ? 'Nenhuma conta cadastrada' : account.holderName),
                  subtitle: account == null
                      ? const Text('Cadastre uma chave Pix ou conta bancária.')
                      : Text(
                          [
                            account.maskedDocument,
                            if (account.pixSummary != null) account.pixSummary!,
                            if (account.bankSummary != null) account.bankSummary!,
                          ].join('\n'),
                        ),
                  isThreeLine: account != null,
                  trailing: TextButton(
                    onPressed: () => _editAccount(context),
                    child: Text(account == null ? 'Cadastrar' : 'Editar'),
                  ),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(state.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),

              // ----- Extrato --------------------------------------------------
              Text('Extrato', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.entries.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Nenhuma movimentação ainda'),
                    subtitle: Text(
                      'Os pagamentos liberados das suas contratações aparecem aqui.',
                    ),
                  ),
                )
              else
                for (final entry in state.entries) _EntryTile(entry: entry),
            ],
          );
        },
      ),
    );
  }
}

/// Uma linha do extrato: verde para entrada, normal para saída.
class _EntryTile extends StatelessWidget {
  final WalletEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sign = entry.isCredit ? '+ ' : '- ';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(entry.isCredit ? Icons.south_west : Icons.north_east),
      ),
      title: Text(entry.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(Formatters.dateTime(entry.createdAt)),
      trailing: Text(
        '$sign${Formatters.currency(entry.amount.abs())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: entry.isCredit ? Colors.green : null,
        ),
      ),
    );
  }
}
