// =============================================================================
// modules/payments/presentation/widgets/wallet_tile.dart
// -----------------------------------------------------------------------------
// ATALHO "MINHA CARTEIRA" exibido no Perfil do profissional.
// =============================================================================

import 'package:flutter/material.dart';

import '../pages/wallet_page.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.account_balance_wallet_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Minha carteira'),
        subtitle: const Text('Saldo, extrato e saques via Pix ou TED'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WalletPage()),
        ),
      ),
    );
  }
}
