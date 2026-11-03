// =============================================================================
// modules/onboarding/presentation/pages/define_location_page.dart
// -----------------------------------------------------------------------------
// TEL08 como TELA PRÓPRIA (variação "Local do set" do modo Contratar).
// Usa o mesmo componente da ativação do perfil (DefineLocationView) e
// DEVOLVE o lugar escolhido para quem abriu a tela (ex.: TEL11).
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/define_location_view.dart';

class DefineLocationPage extends StatefulWidget {
  final String heading;
  final String confirmLabel;
  final String privacyNote;
  final GeoPlace? initialPlace;

  const DefineLocationPage({
    super.key,
    this.heading = 'Local do set',
    this.confirmLabel = 'Confirmar local',
    this.privacyNote = 'O local do set serve só para calcular a distância até os profissionais.',
    this.initialPlace,
  });

  @override
  State<DefineLocationPage> createState() => _DefineLocationPageState();
}

class _DefineLocationPageState extends State<DefineLocationPage> {
  GeoPlace? _place;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localização')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                children: [
                  DefineLocationView(
                    heading: widget.heading,
                    initialPlace: _place,
                    privacyNote: widget.privacyNote,
                    onChanged: (place) => setState(() => _place = place),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Desabilitado até haver um ponto válido (TEL08-E2).
                  onPressed: (_place?.isValid ?? false)
                      ? () => Navigator.of(context).pop(_place)
                      : null,
                  child: Text(widget.confirmLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
