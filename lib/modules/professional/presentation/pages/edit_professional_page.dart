// =============================================================================
// modules/professional/presentation/pages/edit_professional_page.dart
// -----------------------------------------------------------------------------
// TEL18 — EDITAR DADOS PROFISSIONAIS.
//
//   Nome profissional · Canal de contato · Especialidades (chips)
//   + extras do app: Título profissional e "Sobre você"
//   [Salvar alterações]   Cancelar
//
// Mesmas validações da ativação (TEL05 e TEL06). As alterações valem para
// as próximas buscas.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../onboarding/domain/onboarding_validators.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

class EditProfessionalPage extends StatefulWidget {
  const EditProfessionalPage({super.key});

  @override
  State<EditProfessionalPage> createState() => _EditProfessionalPageState();
}

class _EditProfessionalPageState extends State<EditProfessionalPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  late final List<String> _specialties;
  bool _showAll = false;
  bool _isSaving = false;
  String? _specialtiesError;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SessionCubit>().state.profile!;
    _nameController = TextEditingController(text: profile.fullName);
    _contactController = TextEditingController(text: profile.phone ?? '');
    _headlineController = TextEditingController(text: profile.headline ?? '');
    _bioController = TextEditingController(text: profile.bio ?? '');
    // A função principal vem primeiro; depois as outras habilidades.
    _specialties = [
      if (profile.primaryRole != null && profile.primaryRole!.isNotEmpty) profile.primaryRole!,
      ...profile.secondarySkills.where((skill) => skill != profile.primaryRole),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final specialtiesError = OnboardingValidators.specialties(_specialties);
    setState(() => _specialtiesError = specialtiesError);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || specialtiesError != null) return;

    final session = context.read<SessionCubit>();
    setState(() => _isSaving = true);
    final result = await getIt<ProfileRepository>().updateProfile(
      session.state.profile!.copyWith(
        fullName: _nameController.text.trim(),
        phone: _contactController.text.trim(),
        primaryRole: _specialties.first,
        secondarySkills: _specialties.skip(1).toList(),
        headline: _headlineController.text,
        bio: _bioController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (saved) {
        session.updateProfile(saved);
        showAppMessage(context, 'Perfil atualizado!');
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mostra as escolhidas + algumas do catálogo; "+ mais" abre o resto.
    final visible = _showAll
        ? audiovisualRoles
        : {..._specialties, ...audiovisualRoles.take(3)}.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil'), actions: const [ModeIndicatorChip()]),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    LabeledField(
                      label: 'Nome profissional',
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: OnboardingValidators.name,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Canal de contato',
                      child: TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.phone)),
                        validator: OnboardingValidators.contact,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Especialidades', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('A primeira é a sua função principal.', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final role in visible)
                          FilterChip(
                            label: Text(role),
                            selected: _specialties.contains(role),
                            onSelected: (selected) => setState(() {
                              selected ? _specialties.add(role) : _specialties.remove(role);
                            }),
                          ),
                        if (!_showAll)
                          ActionChip(
                            label: const Text('+ mais'),
                            onPressed: () => setState(() => _showAll = true),
                          ),
                      ],
                    ),
                    if (_specialtiesError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _specialtiesError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Título profissional (opcional)',
                      child: TextFormField(
                        controller: _headlineController,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          hintText: 'Ex.: Videomaker de casamentos · 8 anos de set',
                        ),
                      ),
                    ),
                    LabeledField(
                      label: 'Sobre você (opcional)',
                      child: TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText: 'Experiência, equipamentos, trabalhos de destaque...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alterações'),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
