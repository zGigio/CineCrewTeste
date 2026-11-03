// =============================================================================
// modules/home/presentation/widgets/profile_checklist.dart
// -----------------------------------------------------------------------------
// CHECKLIST "COMPLETE SEU PERFIL".
//
// Mostra o que ainda falta preencher. Um perfil completo (com foto,
// função, localização e currículo) aparece melhor nas buscas e passa mais
// confiança — como o indicador de "força do perfil" do LinkedIn.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../profile/domain/entities/user_profile.dart';

/// Um item do checklist: descrição + se já foi concluído.
class _ChecklistItem {
  final String label;
  final bool done;

  const _ChecklistItem(this.label, this.done);
}

class ProfileChecklist extends StatelessWidget {
  final UserProfile profile;

  /// Ação ao tocar em "Completar perfil" (abre a aba Perfil).
  final VoidCallback onCompleteProfile;

  const ProfileChecklist({
    super.key,
    required this.profile,
    required this.onCompleteProfile,
  });

  /// Monta a lista de itens de acordo com os papéis do usuário.
  List<_ChecklistItem> get _items => [
        _ChecklistItem('Foto de perfil', profile.hasAvatar),
        _ChecklistItem('Localização (para as buscas por raio)', profile.hasLocation),
        // Itens que só fazem sentido para profissionais:
        if (profile.isProfessional) ...[
          _ChecklistItem(
            'Função principal',
            profile.primaryRole != null && profile.primaryRole!.isNotEmpty,
          ),
          _ChecklistItem('Currículo em PDF', profile.hasResume),
          _ChecklistItem('Aceite de uso da localização', profile.hasLocationConsent),
        ],
        // Item que só faz sentido para contratantes:
        if (profile.isRecruiter)
          _ChecklistItem(
            'Nome da produtora/empresa',
            profile.companyName != null && profile.companyName!.isNotEmpty,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;
    final doneCount = items.where((item) => item.done).length;
    // Perfil 100% completo: o checklist some para dar espaço à vitrine.
    if (doneCount == items.length) return const SizedBox.shrink();
    final progress = doneCount / items.length; // de 0.0 a 1.0

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete seu perfil', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '$doneCount de ${items.length} itens concluídos',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Barra de progresso.
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            // Um item por linha, com ícone de concluído ou pendente.
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.done ? Colors.green : theme.colorScheme.outline,
                ),
                title: Text(item.label),
              ),
            // Botão só aparece se ainda faltar algo.
            if (doneCount < items.length)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCompleteProfile,
                  child: const Text('Completar perfil'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
