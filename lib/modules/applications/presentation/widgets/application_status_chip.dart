// =============================================================================
// modules/applications/presentation/widgets/application_status_chip.dart
// -----------------------------------------------------------------------------
// SELO COLORIDO com o status da candidatura.
// A cor ajuda a entender a situação de relance:
//   cinza = em análise | azul = entrevista | roxo = proposta
//   verde = contratado | vermelho = reprovado/recusado
// =============================================================================

import 'package:flutter/material.dart';

import '../../domain/entities/job_application.dart';

class ApplicationStatusChip extends StatelessWidget {
  final ApplicationStatus status;

  const ApplicationStatusChip({super.key, required this.status});

  /// Cor e ícone de cada status.
  (Color, IconData) get _style => switch (status) {
        ApplicationStatus.pending => (Colors.blueGrey, Icons.hourglass_top),
        ApplicationStatus.interview => (Colors.blue, Icons.record_voice_over_outlined),
        ApplicationStatus.offerSent => (Colors.deepPurple, Icons.handshake_outlined),
        ApplicationStatus.hired => (Colors.green, Icons.check_circle_outline),
        ApplicationStatus.rejected => (Colors.red, Icons.cancel_outlined),
        ApplicationStatus.offerDeclined => (Colors.red, Icons.block),
      };

  @override
  Widget build(BuildContext context) {
    // "Desestruturação" do registro (record): pega a cor e o ícone.
    final (color, icon) = _style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Fundo clarinho da mesma cor (12% de opacidade).
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
