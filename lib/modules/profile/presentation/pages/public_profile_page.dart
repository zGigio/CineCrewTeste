// =============================================================================
// modules/profile/presentation/pages/public_profile_page.dart
// -----------------------------------------------------------------------------
// PERFIL PÚBLICO de um profissional (como o contratante o vê).
//
// Layout estilo LinkedIn: capa + foto, nome, título profissional e nota;
// depois disponibilidade, habilidades, "Sobre", EXPERIÊNCIA, PORTFÓLIO,
// currículo em PDF, AVALIAÇÕES, contatos e a localização no mapa.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/maps/approx_area_map.dart';
import '../../../../core/widgets/maps/map_preview.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../portfolio/presentation/widgets/profile_cover_header.dart';
import '../../../portfolio/presentation/widgets/profile_showcase.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';

class PublicProfilePage extends StatefulWidget {
  /// Id do usuário cujo perfil será exibido.
  final String userId;

  /// Distância até o set, quando o perfil foi aberto pelos resultados da
  /// busca (TEL14), ex.: "≈ 9 km do set". `null` nos outros casos.
  final String? distanceLabel;

  const PublicProfilePage({super.key, required this.userId, this.distanceLabel});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final ProfileRepository _repository = getIt<ProfileRepository>();

  UserProfile? _profile;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _repository.getProfile(widget.userId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (profile) => setState(() {
        _profile = profile;
        _isLoading = false;
      }),
    );
  }

  /// Abre o currículo (link temporário) no leitor de PDF do celular.
  Future<void> _openResume(UserProfile profile) async {
    final result = await _repository.getResumeUrl(profile.resumePath!);
    if (!mounted) return;
    final url = result.fold<String?>(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return null;
      },
      (link) => link,
    );
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Abre o discador (tel:) ou o app de e-mail (mailto:).
  Future<void> _launch(Uri uri) async {
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      showAppMessage(context, 'Não foi possível abrir este contato.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: const [ModeIndicatorChip()],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _profile == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Não foi possível carregar o perfil',
        message: _error,
        actionLabel: 'Tentar novamente',
        onAction: _load,
      );
    }

    final profile = _profile!;
    final theme = Theme.of(context);

    return ListView(
      children: [
        // Cabeçalho estilo LinkedIn: capa, foto, nome, título e nota.
        // Fica fora do Padding para a capa ocupar a largura toda.
        ProfileCoverHeader(
          profile: profile,
          distanceLabel: widget.distanceLabel == null
              ? null
              : '${widget.distanceLabel} · localização aproximada',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                avatar: Icon(
                  profile.isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
                  color: profile.isAvailable ? Colors.green : Colors.grey,
                  size: 18,
                ),
                label: Text(profile.isAvailable ? 'Disponível' : 'Indisponível no momento'),
              ),

              // Habilidades em "etiquetas" que quebram linha automaticamente.
              if (profile.secondarySkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Habilidades', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in profile.secondarySkills) Chip(label: Text(skill)),
                  ],
                ),
              ],

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Sobre', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(profile.bio!, style: theme.textTheme.bodyLarge),
              ],

              // Experiências e portfólio (fotos e vídeos dos trabalhos).
              ProfileShowcase(userId: profile.id),

              // Currículo em PDF.
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: profile.hasResume ? () => _openResume(profile) : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(profile.hasResume ? 'Ver currículo (PDF)' : 'Currículo não enviado'),
                ),
              ),

              // Avaliações recebidas (estrelas + comentários).
              const SizedBox(height: 24),
              ReviewsSection(userId: profile.id),

              // Contatos.
              const SizedBox(height: 16),
              Text('Contato', style: theme.textTheme.titleMedium),
              if (profile.phone != null && profile.phone!.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(profile.phone!),
                  onTap: () => _launch(Uri(scheme: 'tel', path: profile.phone)),
                ),
              if (profile.email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: Text(profile.email!),
                  onTap: () => _launch(Uri(scheme: 'mailto', path: profile.email)),
                ),

              // Região onde a pessoa atua: só a ÁREA APROXIMADA (~1 km),
              // nunca o endereço. O próprio usuário vê o ponto exato.
              if (profile.hasLocation || profile.hasApproxLocation) ...[
                const SizedBox(height: 16),
                Text(
                  profile.locationLabel.isEmpty
                      ? 'Região onde atua'
                      : 'Região onde atua: ${profile.locationLabel}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (profile.hasLocation)
                  MapPreview(
                    latitude: profile.latitude!,
                    longitude: profile.longitude!,
                    height: 180,
                  )
                else
                  ApproxAreaMap(
                    latitude: profile.approxLatitude!,
                    longitude: profile.approxLongitude!,
                  ),
                const SizedBox(height: 6),
                const AppBanner.info('Localização aproximada, para proteger a privacidade.'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
