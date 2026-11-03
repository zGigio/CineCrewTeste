// =============================================================================
// modules/payments/presentation/widgets/simulated_payment_sheet.dart
// -----------------------------------------------------------------------------
// JANELA DE PAGAMENTO SIMULADO (aberta de baixo para cima).
//
// O contratante escolhe Pix ou cartão e confirma. NÃO há campos de cartão
// nem cobrança: é só a demonstração do fluxo. Devolve `true` se confirmou.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';

Future<bool> showSimulatedPaymentSheet(BuildContext context, {required double amount}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SimulatedPaymentSheet(amount: amount),
  );
  return confirmed ?? false;
}

class _SimulatedPaymentSheet extends StatefulWidget {
  final double amount;

  const _SimulatedPaymentSheet({required this.amount});

  @override
  State<_SimulatedPaymentSheet> createState() => _SimulatedPaymentSheetState();
}

class _SimulatedPaymentSheetState extends State<_SimulatedPaymentSheet> {
  /// Forma escolhida (só muda o texto: nada é cobrado).
  String _method = 'pix';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pagar com garantia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              Formatters.currency(widget.amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // SegmentedButton: botões lado a lado, um selecionado por vez.
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pix', label: Text('Pix'), icon: Icon(Icons.pix)),
                ButtonSegment(
                  value: 'cartao',
                  label: Text('Cartão'),
                  icon: Icon(Icons.credit_card),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (selection) => setState(() => _method = selection.first),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Seu dinheiro fica protegido'),
                subtitle: Text(
                  'O valor fica guardado na plataforma e só vai para o profissional '
                  'quando vocês dois confirmarem que o serviço foi realizado.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pagamento SIMULADO para demonstração: nenhum valor real é cobrado.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                _method == 'pix' ? 'Pagar com Pix (simulado)' : 'Pagar com cartão (simulado)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
