// =============================================================================
// modules/explore/presentation/pages/define_search_page.dart
// -----------------------------------------------------------------------------
// TEL11 — DEFINIR BUSCA E PROJETO.
//
//   Sua busca
//   [📍 Petrolina · PE  Local do set confirmado    (Alterar)]
//   Especialidades requeridas: (chips, "+ mais")
//   Raio máximo (km): [50]       (entre 1 e 200)
//   Nome do projeto (opcional): [Longa "Horizonte Seco"]
//   [🔍 Buscar profissionais]
//
// TEL11-E1: erros por campo (local, especialidade, raio).
// Com nome, o projeto é SALVO (TEL15) e pode ser repetido depois.
// Devolve os critérios válidos para quem abriu a tela.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../onboarding/presentation/pages/define_location_page.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/search_criteria.dart';
import '../../domain/search_rules.dart';
import '../cubit/projects_cubit.dart';

class DefineSearchPage extends StatefulWidget {
  final SearchCriteria initial;

  /// Já mostra os erros ao abrir (ex.: "Buscar" do Explorar incompleto).
  final bool validateOnOpen;

  const DefineSearchPage({
    super.key,
    this.initial = const SearchCriteria(),
    this.validateOnOpen = false,
  });

  @override
  State<DefineSearchPage> createState() => _DefineSearchPageState();
}

class _DefineSearchPageState extends State<DefineSearchPage> {
  late GeoPlace? _place;
  late List<String> _specialties;
  late final TextEditingController _radiusController;
  late final TextEditingController _nameController;
  Map<SearchField, String> _errors = const {};
  bool _showAll = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _place = widget.initial.place;
    _specialties = List.of(widget.initial.specialties);
    _radiusController = TextEditingController(text: '${widget.initial.radiusKm}');
    _nameController = TextEditingController(text: widget.initial.projectName ?? '');
    if (widget.validateOnOpen) _errors = SearchRules.validate(_criteria());
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  SearchCriteria _criteria() => SearchCriteria(
        place: _place,
        specialties: List.of(_specialties),
        radiusKm: int.tryParse(_radiusController.text.trim()) ?? 0,
        onlyAvailable: widget.initial.onlyAvailable,
        projectId: widget.initial.projectId,
        projectName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );

  Future<void> _pickPlace() async {
    final place = await Navigator.of(context).push<GeoPlace>(
      MaterialPageRoute(builder: (_) => DefineLocationPage(initialPlace: _place)),
    );
    if (place != null) {
      setState(() {
        _place = place;
        _errors = Map.of(_errors)..remove(SearchField.place);
      });
    }
  }

  Future<void> _submit() async {
    var criteria = _criteria();
    final errors = SearchRules.validate(criteria);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    // Com nome: salva/atualiza o projeto antes de buscar (P13).
    final name = criteria.projectName;
    if (name != null) {
      setState(() => _isSaving = true);
      final (saved, error) = await context.read<ProjectsCubit>().save(
            Project(
              id: criteria.projectId,
              name: name,
              place: criteria.place!,
              radiusKm: criteria.radiusKm,
              specialties: criteria.specialties,
            ),
          );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (error != null) {
        showAppMessage(context, error, isError: true);
        return;
      }
      criteria = criteria.copyWith(projectId: saved?.id);
    }
    if (!mounted) return;
    Navigator.of(context).pop(criteria);
  }

  Widget _error(SearchField field) {
    final message = _errors[field];
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeError = _errors.containsKey(SearchField.place);
    final visibleRoles = _showAll
        ? audiovisualRoles
        : {..._specialties, ...audiovisualRoles.take(4)}.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar'), actions: const [ModeIndicatorChip()]),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                children: [
                  Text('Sua busca', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // ---- Local do set -----------------------------------------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: placeError ? AppColors.error : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: _place == null ? AppColors.textSecondary : AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _place == null ? 'Definir local do set' : _criteria().placeLabel,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_place != null)
                                Text('Local do set confirmado', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _pickPlace,
                          child: Text(_place == null ? 'Definir' : 'Alterar'),
                        ),
                      ],
                    ),
                  ),
                  _error(SearchField.place),
                  const SizedBox(height: 16),

                  // ---- Especialidades ---------------------------------------
                  Text('Especialidades requeridas', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final role in visibleRoles)
                        FilterChip(
                          label: Text(role),
                          selected: _specialties.contains(role),
                          onSelected: (selected) => setState(() {
                            selected ? _specialties.add(role) : _specialties.remove(role);
                            _errors = Map.of(_errors)..remove(SearchField.specialties);
                          }),
                        ),
                      if (!_showAll)
                        ActionChip(
                          label: const Text('+ mais'),
                          onPressed: () => setState(() => _showAll = true),
                        ),
                    ],
                  ),
                  _error(SearchField.specialties),
                  const SizedBox(height: 6),
                  Text(
                    'Mostra profissionais com qualquer uma das especialidades escolhidas.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // ---- Raio -------------------------------------------------
                  LabeledField(
                    label: 'Raio máximo (km)',
                    child: TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        errorText: _errors[SearchField.radius],
                        helperText: _radiusHelper(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Projeto (opcional) -----------------------------------
                  LabeledField(
                    label: 'Nome do projeto (opcional)',
                    child: TextField(
                      controller: _nameController,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ex.: Longa "Horizonte Seco"',
                        errorText: _errors[SearchField.projectName],
                        helperText: 'Com nome, a busca fica salva em Projetos.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: AppTheme.highlightButton,
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar profissionais'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Texto de apoio do raio (some quando há erro).
  String? _radiusHelper() => _errors.containsKey(SearchField.radius)
      ? null
      : 'Entre ${RadiusRules.min} e ${RadiusRules.max} km';
}
