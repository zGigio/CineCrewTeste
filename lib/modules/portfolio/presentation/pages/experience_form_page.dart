// =============================================================================
// modules/portfolio/presentation/pages/experience_form_page.dart
// -----------------------------------------------------------------------------
// FORMULÁRIO DE EXPERIÊNCIA (nova ou edição):
//   função, produção/empresa, tipo de projeto, início, fim (ou "trabalho
//   atual") e descrição. Só mês e ano importam: guardamos o dia 1º.
// Devolve `true` ao salvar.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/experience.dart';
import '../../domain/usecases/portfolio_usecases.dart';
import '../cubit/portfolio_cubit.dart';

class ExperienceFormPage extends StatefulWidget {
  /// `null` = nova experiência.
  final Experience? experience;

  const ExperienceFormPage({super.key, this.experience});

  @override
  State<ExperienceFormPage> createState() => _ExperienceFormPageState();
}

class _ExperienceFormPageState extends State<ExperienceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roleController;
  late final TextEditingController _productionController;
  late final TextEditingController _descriptionController;

  String? _category;
  late DateTime _start;
  DateTime? _end;
  late bool _isCurrent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final experience = widget.experience;
    _roleController = TextEditingController(text: experience?.role ?? '');
    _productionController = TextEditingController(text: experience?.production ?? '');
    _descriptionController = TextEditingController(text: experience?.description ?? '');
    _category = experience?.category;
    final now = DateTime.now();
    _start = experience?.startDate ?? DateTime(now.year, now.month);
    _end = experience?.endDate;
    _isCurrent = experience != null && experience.isCurrent;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _productionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Abre o calendário começando pela escolha do ANO; guarda o dia 1º do mês.
  Future<DateTime?> _pickMonth(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Escolha o mês (o dia é ignorado)',
    );
    return picked == null ? null : DateTime(picked.year, picked.month);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isCurrent && _end == null) {
      showAppMessage(context, 'Escolha o mês de término ou marque "Trabalho atual".',
          isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final error = await context.read<PortfolioCubit>().saveExperience(
          Experience(
            id: widget.experience?.id,
            role: _roleController.text,
            production: _productionController.text,
            category: _category,
            startDate: _start,
            endDate: _isCurrent ? null : _end,
            description: _descriptionController.text,
          ),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      showAppMessage(context, error, isError: true);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experience == null ? 'Nova experiência' : 'Editar experiência'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campo livre + menu com as funções padronizadas como atalho.
            TextFormField(
              controller: _roleController,
              decoration: InputDecoration(
                labelText: 'Sua função',
                hintText: 'Ex.: Diretor(a) de Fotografia',
                suffixIcon: PopupMenuButton<String>(
                  tooltip: 'Escolher da lista',
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (role) => setState(() => _roleController.text = role),
                  itemBuilder: (_) => [
                    for (final role in audiovisualRoles)
                      PopupMenuItem(value: role, child: Text(role)),
                  ],
                ),
              ),
              validator: (value) =>
                  (value?.trim().length ?? 0) < 2 ? 'Informe a sua função.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _productionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Produção ou empresa',
                hintText: 'Ex.: Curta "Maré Alta" / Produtora XYZ',
              ),
              validator: (value) =>
                  (value?.trim().length ?? 0) < 2 ? 'Informe a produção ou empresa.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Tipo de projeto (opcional)'),
              items: [
                for (final category in experienceCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Início'),
              trailing: Text(monthYear(_start)),
              onTap: () async {
                final picked = await _pickMonth(_start);
                if (picked != null) setState(() => _start = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trabalho atual'),
              value: _isCurrent,
              onChanged: (value) => setState(() => _isCurrent = value),
            ),
            if (!_isCurrent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Término'),
                trailing: Text(_end == null ? 'Escolher' : monthYear(_end!)),
                onTap: () async {
                  final picked = await _pickMonth(_end ?? _start);
                  if (picked != null) setState(() => _end = picked);
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: PortfolioRules.maxDescription,
              decoration: const InputDecoration(
                labelText: 'O que você fez (opcional)',
                hintText: 'Equipamentos, equipe, resultado, prêmios...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar experiência'),
            ),
          ],
        ),
      ),
    );
  }
}
