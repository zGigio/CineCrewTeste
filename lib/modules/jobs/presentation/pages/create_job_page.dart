// =============================================================================
// modules/jobs/presentation/pages/create_job_page.dart
// -----------------------------------------------------------------------------
// TELA "PUBLICAR VAGA" (modo contratante).
//
// O contratante informa:
//   O QUE   -> título, função procurada, descrição e cachê;
//   QUANDO  -> data/hora de início e de fim;
//   ONDE    -> toca no mapa (ou usa o GPS) + endereço, cidade e UF.
// Ao publicar, o CreateJobUseCase valida as regras e grava no Supabase.
// Ao terminar, a tela fecha devolvendo `true` (para a lista recarregar).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/maps/location_picker_map.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/job_draft.dart';
import '../../domain/usecases/create_job_usecase.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  String? _role;
  DateTime? _startsAt;
  DateTime? _endsAt;
  LatLng? _point;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Sugere a cidade/UF e o ponto do perfil do contratante.
    final profile = context.read<SessionCubit>().state.profile;
    if (profile != null) {
      _cityController.text = profile.city ?? '';
      _stateController.text = profile.state ?? '';
      if (profile.hasLocation) {
        _point = LatLng(profile.latitude!, profile.longitude!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  /// Abre o calendário e depois o relógio; devolve a data+hora escolhida.
  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)), // até 2 anos à frente
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;

    // Junta a data escolhida com a hora escolhida.
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final value = await _pickDateTime(initial: _startsAt);
    if (value == null) return;
    setState(() {
      _startsAt = value;
      // Se o fim ficou antes do novo início, sugere fim = início + 8 horas.
      if (_endsAt == null || !_endsAt!.isAfter(value)) {
        _endsAt = value.add(const Duration(hours: 8));
      }
    });
  }

  Future<void> _pickEnd() async {
    final value = await _pickDateTime(initial: _endsAt ?? _startsAt);
    if (value != null) setState(() => _endsAt = value);
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    // Campos que não são texto: conferidos aqui com mensagens claras.
    if (_startsAt == null || _endsAt == null) {
      showAppMessage(context, 'Informe o início e o fim do trabalho.', isError: true);
      return;
    }
    if (_point == null) {
      showAppMessage(context, 'Marque o local da gravação no mapa.', isError: true);
      return;
    }

    final profile = context.read<SessionCubit>().state.profile!;

    // Monta o rascunho com os dados do formulário.
    final draft = JobDraft(
      recruiterId: profile.id,
      title: _titleController.text,
      description: _descriptionController.text,
      requiredRole: _role ?? '',
      fee: Formatters.parseCurrency(_feeController.text) ?? 0,
      startsAt: _startsAt!,
      endsAt: _endsAt!,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text.toUpperCase(),
      latitude: _point!.latitude,
      longitude: _point!.longitude,
    );

    setState(() => _isSaving = true);
    // O caso de uso valida as regras de negócio e grava no banco.
    final result = await getIt<CreateJobUseCase>()(draft);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (_) {
        showAppMessage(context, 'Vaga publicada!');
        Navigator.of(context).pop(true); // avisa a lista para recarregar
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vaga')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- O QUE ---------------------------------------------------
            Text('O que', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título da vaga',
                hintText: 'Ex.: Videomaker para casamento',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.requiredField(value, fieldName: 'O título'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Função procurada',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final role in audiovisualRoles)
                  DropdownMenuItem(value: role, child: Text(role)),
              ],
              onChanged: (value) => setState(() => _role = value),
              validator: (value) => value == null ? 'Escolha a função.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cachê (R\$)',
                hintText: 'Ex.: 1500,00',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Formatters.parseCurrency(value ?? '') == null
                  ? 'Informe um valor válido.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Detalhes do trabalho, equipamentos, requisitos...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            // ----- QUANDO --------------------------------------------------
            const SizedBox(height: 8),
            Text('Quando', style: theme.textTheme.titleMedium),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Início'),
                    subtitle: Text(
                      _startsAt == null ? 'Toque para escolher' : Formatters.dateTime(_startsAt!),
                    ),
                    onTap: _pickStart,
                  ),
                  ListTile(
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Fim'),
                    subtitle: Text(
                      _endsAt == null ? 'Toque para escolher' : Formatters.dateTime(_endsAt!),
                    ),
                    onTap: _pickEnd,
                  ),
                ],
              ),
            ),

            // ----- ONDE ----------------------------------------------------
            const SizedBox(height: 16),
            Text('Onde', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            LocationPickerMap(
              initialPoint: _point,
              onChanged: (point) => setState(() => _point = point),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Endereço (opcional)',
                hintText: 'Ex.: Rua das Laranjeiras, 100',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isSaving ? null : _publish,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publicar vaga'),
            ),
          ],
        ),
      ),
    );
  }
}
