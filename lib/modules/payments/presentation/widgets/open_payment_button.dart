// =============================================================================
// modules/payments/presentation/widgets/open_payment_button.dart
// -----------------------------------------------------------------------------
// BOTÃO "PAGAMENTO" usado nas candidaturas com status CONTRATADO
// (ao lado do "Abrir chat"), para os dois lados da contratação.
// =============================================================================

import 'package:flutter/material.dart';

import '../pages/payment_page.dart';

class OpenPaymentButton extends StatelessWidget {
  final String applicationId;
  final String jobTitle;

  const OpenPaymentButton({super.key, required this.applicationId, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentPage(applicationId: applicationId, jobTitle: jobTitle),
        ),
      ),
      icon: const Icon(Icons.shield_outlined),
      label: const Text('Pagamento'),
    );
  }
}
