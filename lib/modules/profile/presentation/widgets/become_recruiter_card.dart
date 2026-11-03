// =============================================================================
// modules/profile/presentation/widgets/become_recruiter_card.dart
// -----------------------------------------------------------------------------
// CARTÃO "TORNE-SE UM CONTRATANTE".
//
// Inspirado no "Torne-se um anfitrião" do Airbnb: convida quem só usa o app
// como profissional a também publicar vagas, sem precisar de outra conta.
// =============================================================================

import 'package:flutter/material.dart';

class BecomeRecruiterCard extends StatelessWidget {
  /// Ação ao tocar no cartão (ativa o papel de contratante).
  final VoidCallback onPressed;

  const BecomeRecruiterCard({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      // InkWell: efeito de "onda" ao tocar e torna o cartão clicável.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Texto ocupa todo o espaço disponível (Expanded).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Torne-se um contratante',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publique vagas e encontre profissionais do '
                      'audiovisual perto de você. É fácil começar.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Ilustração simples com ícone.
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.business_center_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
