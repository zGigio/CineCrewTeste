// =============================================================================
// modules/onboarding/presentation/pages/professional_onboarding_page.dart
// -----------------------------------------------------------------------------
// ATIVAÇÃO DO PERFIL PROFISSIONAL em 4 passos (Pranchas 03 e 04):
//
//   Passo 1 · TEL05  Seus dados profissionais (nome e contato)
//   Passo 2 · TEL06  Suas especialidades (pelo menos uma)
//   Passo 3 · TEL07  Como usamos sua localização (aceite — LGPD)
//   Passo 4 · TEL08  Onde você atua (endereço, CEP, mapa ou GPS)
//
// Os passos ficam numa PageView sem deslizar com o dedo: só avançam pelos
// botões, depois de validar. Tudo é salvo de uma vez no final, pelo caso
// de uso ActivateProfessionalProfileUseCase.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/step_progress.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../domain/entities/location_terms.dart';
import '../../domain/onboarding_validators.dart';
import '../../domain/usecases/activate_profiles_usecases.dart';
import '../widgets/define_location_view.dart';

class ProfessionalOnboardingPage extends StatefulWidget {
  const ProfessionalOnboardingPage({super.key});

  @override
  State<ProfessionalOnboardingPage> createState() => _ProfessionalOnboardingPageState();
}

class _ProfessionalOnboardingPageState extends State<ProfessionalOnboardingPage> {
  static const int _totalSteps = 4;

  final _pageController = PageController();
  final _dataFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;

  int _step = 0; // 0 a 3
  final List<String> _specialties = [];
  bool _acceptedTerms = false;
  GeoPlace? _place;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pré-preenche com o que a conta já tem (o nome da conta é sugerido).
    final profile = context.read<SessionCubit>().state.profile!;
    _nameController = TextEditingController(text: profile.fullName);
    _contactController = TextEditingController(text: profile.phone ?? '');
    if (profile.primaryRole != null && audiovisualRoles.contains(profile.primaryRole)) {
      _specialties.add(profile.primaryRole!);
    }
    _specialties.addAll(
      profile.secondarySkills.where((s) => audiovisualRoles.contains(s) && !_specialties.contains(s)),
    );
    _acceptedTerms = profile.hasLocationConsent;
    if (profile.hasLocation) {
      _place = GeoPlace(
        latitude: profile.latitude!,
        longitude: profile.longitude!,
        label: profile.locationLabel.isEmpty ? 'Localização salva' : profile.locationLabel,
        city: profile.city,
        state: profile.state,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Voltar: passo anterior, ou sai da tela no primeiro passo.
  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goTo(_step - 1);
    }
  }

  Future<void> _finish() async {
    final session = context.read<SessionCubit>();
    setState(() => _isSaving = true);
    final result = await getIt<ActivateProfessionalProfileUseCase>()(
      ActivateProfessionalParams(
        profile: session.state.profile!,
        draft: ProfessionalDraft(
          name: _nameController.text,
          contact: _contactController.text,
          specialties: List.of(_specialties),
          acceptedTerms: _acceptedTerms,
          place: _place,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (saved) {
        session.updateProfile(saved);
        session.switchMode(AppMode.professional);
        showAppMessage(context, 'Perfil profissional ativo! Você já aparece nas buscas.');
        // Volta para a raiz: o AuthGate mostra o app no modo Profissional.
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // O botão "voltar" do Android volta um passo em vez de sair.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(_step == 3 ? 'Localização' : 'Perfil profissional'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: StepProgress(current: _step + 1, total: _totalSteps),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDataStep(),
                    _buildSpecialtiesStep(),
                    _buildConsentStep(),
                    _buildLocationStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout comum: conteúdo rolável + botões fixos embaixo.
  Widget _stepLayout({required List<Widget> children, required List<Widget> buttons}) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons),
        ),
      ],
    );
  }

  Widget _title(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---- Passo 1 · TEL05 -------------------------------------------------------
  Widget _buildDataStep() {
    return Form(
      key: _dataFormKey,
      child: _stepLayout(
        children: [
          _title('Seus dados profissionais', 'Como os contratantes verão você.'),
          LabeledField(
            label: 'Nome profissional',
            child: TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Como você é conhecido no set'),
              validator: OnboardingValidators.name,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Canal de contato',
            child: TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Ex.: (21) 99999-8888',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: OnboardingValidators.contact,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O telefone aparece só para contratantes logados, no seu perfil.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        buttons: [
          FilledButton(
            onPressed: () {
              if (_dataFormKey.currentState!.validate()) _goTo(1);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // ---- Passo 2 · TEL06 -------------------------------------------------------
  Widget _buildSpecialtiesStep() {
    return _stepLayout(
      children: [
        _title('Suas especialidades', 'Selecione ao menos uma. A primeira vira sua função principal.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in audiovisualRoles)
              FilterChip(
                label: Text(role),
                selected: _specialties.contains(role),
                onSelected: (selected) => setState(() {
                  selected ? _specialties.add(role) : _specialties.remove(role);
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _specialties.length == 1 ? '1 selecionada' : '${_specialties.length} selecionadas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      buttons: [
        FilledButton(
          // Desabilitado sem seleção (TEL06).
          onPressed: _specialties.isEmpty ? null : () => _goTo(2),
          child: const Text('Continuar'),
        ),
        TextButton(onPressed: _back, child: const Text('Voltar')),
      ],
    );
  }

  // ---- Passo 3 · TEL07 -------------------------------------------------------
  Widget _buildConsentStep() {
    const icons = [Icons.place, Icons.shield, Icons.sync];
    return _stepLayout(
      children: [
        _title('Como usamos sua localização', 'Leia antes de continuar.'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (var i = 0; i < LocationTerms.points.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icons[i], color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(LocationTerms.points[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          title: const Text(LocationTerms.checkboxText),
        ),
        Text(
          'Versão do termo: ${LocationTerms.version}. Data e hora do aceite ficam registradas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      buttons: [
        FilledButton(
          // Só com a caixa marcada (sem aceite, o cadastro não prossegue).
          onPressed: _acceptedTerms ? () => _goTo(3) : null,
          child: const Text('Aceitar e continuar'),
        ),
        TextButton(onPressed: _back, child: const Text('Voltar')),
      ],
    );
  }

  // ---- Passo 4 · TEL08 -------------------------------------------------------
  Widget _buildLocationStep() {
    return _stepLayout(
      children: [
        DefineLocationView(
          heading: 'Onde você atua',
          initialPlace: _place,
          onChanged: (place) => setState(() => _place = place),
        ),
      ],
      buttons: [
        FilledButton(
          onPressed: (_place?.isValid ?? false) && !_isSaving ? _finish : null,
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Concluir perfil profissional'),
        ),
      ],
    );
  }
}
