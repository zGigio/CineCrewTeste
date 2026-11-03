// =============================================================================
// modules/payments/presentation/pages/payment_page.dart
// -----------------------------------------------------------------------------
// TELA "PAGAMENTO COM GARANTIA" de uma contratação.
//
// A mesma tela serve para os dois lados; os botões mudam conforme QUEM está
// vendo e a ETAPA atual:
//   * Contratante: paga -> confirma o serviço;
//   * Profissional: aguarda o pagamento -> confirma o serviço -> vê a carteira;
//   * Os dois: podem abrir disputa enquanto o valor está em garantia.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/escrow_usecases.dart';
import '../cubit/payment_cubit.dart';
import '../widgets/escrow_timeline.dart';
import '../widgets/simulated_payment_sheet.dart';
import 'wallet_page.dart';
import '../../../reviews/presentation/widgets/review_button.dart';

class PaymentPage extends StatelessWidget {
  final String applicationId;
  final String jobTitle;

  const PaymentPage({super.key, required this.applicationId, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.profile!.id;
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>()..watch(applicationId: applicationId, userId: userId),
      child: _PaymentView(jobTitle: jobTitle, userId: userId),
    );
  }
}

class _PaymentView extends StatelessWidget {
  final String jobTitle;
  final String userId;

  const _PaymentView({required this.jobTitle, required this.userId});

  /// Mostra o resultado de uma ação (erro em vermelho ou sucesso).
  void _showResult(BuildContext context, String? error, String successMessage) {
    if (!context.mounted) return;
    showAppMessage(context, error ?? successMessage, isError: error != null);
  }

  Future<void> _pay(BuildContext context, Payment payment) async {
    final confirmed = await showSimulatedPaymentSheet(context, amount: payment.amount);
    if (!confirmed || !context.mounted) return;
    final error = await context.read<PaymentCubit>().pay();
    if (!context.mounted) return;
    _showResult(context, error, 'Pagamento feito! O valor está em garantia. 🔒');
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Confirmar serviço realizado?',
      message: 'Confirme apenas se o trabalho foi feito como combinado. '
          'Quando os dois confirmarem, o valor é liberado ao profissional.',
      confirmLabel: 'Confirmar',
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<PaymentCubit>().confirmService();
    if (!context.mounted) return;
    _showResult(context, error, 'Confirmação registrada.');
  }

  Future<void> _dispute(BuildContext context) async {
    final reason = await _askDisputeReason(context);
    if (reason == null || !context.mounted) return;
    final error = await context.read<PaymentCubit>().openDispute(reason);
    if (!context.mounted) return;
    _showResult(context, error, 'Disputa aberta. O valor continua guardado.');
  }

  /// Janela para descrever o problema. Devolve o texto, ou `null` se cancelou.
  Future<String?> _askDisputeReason(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abrir disputa'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: OpenDisputeUseCase.maxReasonLength,
            decoration: const InputDecoration(
              hintText: 'Conte o que aconteceu (ex.: o serviço não foi entregue).',
            ),
            validator: (value) =>
                (value?.trim().length ?? 0) < OpenDisputeUseCase.minReasonLength
                    ? 'Escreva pelo menos 10 caracteres.'
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('Abrir disputa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento com garantia')),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final payment = state.payment;
          if (payment == null) {
            return const EmptyState(
              icon: Icons.money_off,
              title: 'Sem pagamento para esta contratação',
              message: 'Vagas sem cachê não usam a garantia.',
            );
          }
          return _buildContent(context, payment, state.isBusy);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Payment payment, bool isBusy) {
    final theme = Theme.of(context);
    final isPayer = payment.isPayer(userId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ----- Valor e vaga -------------------------------------------------
        Text(jobTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          Formatters.currency(payment.amount),
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Chip(
          avatar: Icon(_statusIcon(payment.status), size: 18),
          label: Text(payment.status.label),
        ),
        const SizedBox(height: 16),
        EscrowTimeline(
          currentStep: payment.step,
          isDisputed: payment.status == PaymentStatus.disputed,
        ),
        const SizedBox(height: 24),

        // ----- Explicação da etapa atual ------------------------------------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_explanation(payment, isPayer)),
          ),
        ),

        // ----- Confirmações (enquanto em garantia) --------------------------
        if (payment.status == PaymentStatus.held) ...[
          const SizedBox(height: 8),
          _ConfirmationRow(label: 'Contratante', confirmed: payment.payerConfirmed),
          _ConfirmationRow(label: 'Profissional', confirmed: payment.payeeConfirmed),
        ],

        if (payment.status == PaymentStatus.disputed && payment.disputeReason != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Motivo da disputa'),
              subtitle: Text(payment.disputeReason!),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ----- Ações ----------------------------------------------------------
        if (payment.canPay(userId))
          FilledButton.icon(
            onPressed: isBusy ? null : () => _pay(context, payment),
            icon: const Icon(Icons.lock_outline),
            label: Text('Pagar ${Formatters.currency(payment.amount)}'),
          ),
        if (payment.canConfirm(userId))
          FilledButton.icon(
            onPressed: isBusy ? null : () => _confirm(context),
            icon: const Icon(Icons.task_alt),
            label: const Text('Confirmar serviço realizado'),
          ),
        if (payment.status == PaymentStatus.released && payment.isPayee(userId))
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WalletPage()),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Ver minha carteira'),
          ),
        // Pagamento liberado: hora de avaliar a outra parte.
        if (payment.status == PaymentStatus.released) ...[
          const SizedBox(height: 8),
          Center(
            child: ReviewButton(
              applicationId: payment.applicationId,
              title: isPayer ? 'Avaliar o profissional' : 'Avaliar o contratante',
            ),
          ),
        ],
        if (payment.canDispute(userId)) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isBusy ? null : () => _dispute(context),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Tive um problema'),
          ),
        ],
        if (isBusy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  static IconData _statusIcon(PaymentStatus status) => switch (status) {
        PaymentStatus.awaitingPayment => Icons.hourglass_empty,
        PaymentStatus.held => Icons.lock_outline,
        PaymentStatus.released => Icons.check_circle_outline,
        PaymentStatus.refunded => Icons.undo,
        PaymentStatus.disputed => Icons.warning_amber,
      };

  /// Texto explicativo para cada etapa, do ponto de vista de quem está vendo.
  String _explanation(Payment payment, bool isPayer) {
    switch (payment.status) {
      case PaymentStatus.awaitingPayment:
        return isPayer
            ? 'Pague para garantir a contratação. O valor fica guardado na '
                'plataforma e só vai para o profissional depois do serviço.'
            : 'Aguardando o contratante pagar. Você recebe uma notificação '
                'assim que o valor estiver em garantia.';
      case PaymentStatus.held:
        if (payment.confirmedBy(userId)) {
          return 'Você já confirmou. Falta a outra parte confirmar para '
              'liberar o pagamento.';
        }
        return isPayer
            ? 'O valor está guardado. Depois do serviço, confirme que o '
                'trabalho foi realizado.'
            : 'O valor já está garantido! Faça o serviço e depois confirme '
                'aqui que ele foi realizado.';
      case PaymentStatus.released:
        final date = payment.releasedAt == null
            ? ''
            : ' em ${Formatters.date(payment.releasedAt!)}';
        return isPayer
            ? 'Pagamento liberado ao profissional$date. Obrigado!'
            : 'Pagamento liberado$date! O valor está na sua carteira e pode '
                'ser sacado via Pix ou TED.';
      case PaymentStatus.disputed:
        return 'Disputa aberta: o valor continua guardado até a análise da '
            'plataforma (nesta versão de demonstração, a análise é simulada).';
      case PaymentStatus.refunded:
        return 'O valor foi devolvido ao contratante.';
    }
  }
}

/// Linha "Contratante ✓ confirmou" / "Profissional ⏳ aguardando".
class _ConfirmationRow extends StatelessWidget {
  final String label;
  final bool confirmed;

  const _ConfirmationRow({required this.label, required this.confirmed});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: confirmed ? Colors.green : null,
      ),
      title: Text(label),
      trailing: Text(confirmed ? 'Confirmou' : 'Aguardando'),
    );
  }
}
