// =============================================================================
// modules/professional/presentation/pages/my_professional_profile_page.dart
// -----------------------------------------------------------------------------
// TEL17 — MEU PERFIL PROFISSIONAL.
//
//   [capa + foto]                    (Trocar capa) (Trocar foto)
//   Leonardo Fontes   Visível nas buscas          [✎ Editar]   -> TEL18
//   ESPECIALIDADES (chips)
//   📍 LOCALIZAÇÃO-BASE  Centro, Rio de Janeiro · RJ   [Alterar] -> TEL08
//   🔗 PORTFÓLIO  2 itens                            [Gerenciar] -> TEL19
//   📄 CURRÍCULO (extra)                              [Enviar/Ver]
//   [Ver como os contratantes veem]
//
// TEL17-E1 (perfil incompleto): "Não visível nas buscas" + aviso + botão
// de destaque para concluir o que falta.
// =============================================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/geocoding/geo_place.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../../home/presentation/widgets/mode_indicator_chip.dart';
import '../../../onboarding/presentation/pages/define_location_page.dart';
import '../../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../../portfolio/domain/repositories/portfolio_repository.dart';
import '../../../portfolio/presentation/pages/manage_portfolio_page.dart';
import '../../../portfolio/presentation/widgets/profile_cover_header.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/pages/public_profile_page.dart';
import 'edit_professional_page.dart';

class MyProfessionalProfilePage extends StatefulWidget {
  const MyProfessionalProfilePage({super.key});

  @override
  State<MyProfessionalProfilePage> createState() => _MyProfessionalProfilePageState();
}

class _MyProfessionalProfilePageState extends State<MyProfessionalProfilePage> {
  /// Tamanho máximo do currículo: 5 MB.
  static const int _maxResumeBytes = 5 * 1024 * 1024;

  final ProfileRepository _repository = getIt<ProfileRepository>();
  int? _portfolioCount;

  /// Qual envio está em andamento ('foto', 'capa', 'curriculo', 'local').
  String? _busy;

  @override
  void initState() {
    super.initState();
    _loadPortfolioCount();
  }

  SessionCubit get _session => context.read<SessionCubit>();
  UserProfile get _profile => _session.state.profile!;

  Future<void> _loadPortfolioCount() async {
    final result = await getIt<PortfolioRepository>().getItems(_profile.id);
    if (!mounted) return;
    setState(() => _portfolioCount = result.fold((_) => 0, (items) => items.length));
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Executa um envio e aplica o perfil atualizado.
  Future<void> _withBusy(String what, Future<UserProfile?> Function() action, String success) async {
    setState(() => _busy = what);
    final updated = await action();
    if (!mounted) return;
    setState(() => _busy = null);
    if (updated != null) {
      _session.updateProfile(updated);
      showAppMessage(context, success);
    }
  }

  /// Aguarda o envio: em caso de erro mostra a mensagem e devolve `null`;
  /// em caso de sucesso devolve o perfil com o valor novo aplicado.
  Future<UserProfile?> _handle<T>(
    Future<Either<Failure, T>> request,
    UserProfile Function(T value) apply,
  ) async {
    final result = await request;
    return result.fold<UserProfile?>(
      (failure) {
        if (mounted) showAppMessage(context, failure.message, isError: true);
        return null;
      },
      apply,
    );
  }

  Future<void> _changePhoto({required bool cover}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: cover ? 1600 : 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    await _withBusy(
      cover ? 'capa' : 'foto',
      () => _handle<String>(
        cover
            ? _repository.uploadCover(userId: _profile.id, bytes: bytes)
            : _repository.uploadAvatar(userId: _profile.id, bytes: bytes),
        (url) => cover ? _profile.copyWith(coverUrl: url) : _profile.copyWith(avatarUrl: url),
      ),
      cover ? 'Capa atualizada!' : 'Foto atualizada!',
    );
  }

  Future<void> _uploadResume() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxResumeBytes) {
      if (mounted) showAppMessage(context, 'O PDF deve ter no máximo 5 MB.', isError: true);
      return;
    }
    await _withBusy(
      'curriculo',
      () => _handle<String>(
        _repository.uploadResume(userId: _profile.id, bytes: bytes),
        (path) => _profile.copyWith(resumePath: path),
      ),
      'Currículo enviado!',
    );
  }

  Future<void> _openResume() async {
    final result = await _repository.getResumeUrl(_profile.resumePath!);
    if (!mounted) return;
    await result.fold<Future<void>>(
      (failure) async => showAppMessage(context, failure.message, isError: true),
      (url) async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
    );
  }

  /// "Alterar" localização-base: abre a TEL08 e salva o ponto escolhido.
  Future<void> _changeLocation() async {
    final profile = _profile;
    final place = await Navigator.of(context).push<GeoPlace>(
      MaterialPageRoute(
        builder: (_) => DefineLocationPage(
          heading: 'Onde você atua',
          confirmLabel: 'Confirmar este ponto',
          privacyNote: 'Seu endereço exato não é exibido a contratantes.',
          initialPlace: profile.hasLocation
              ? GeoPlace(
                  latitude: profile.latitude!,
                  longitude: profile.longitude!,
                  label: profile.locationLabel,
                  city: profile.city,
                  state: profile.state,
                )
              : null,
        ),
      ),
    );
    if (place == null || !mounted) return;
    await _withBusy(
      'local',
      () => _handle<UserProfile>(
        _repository.updateProfile(
          profile.copyWith(
            latitude: place.latitude,
            longitude: place.longitude,
            city: place.city ?? '',
            state: place.state ?? '',
          ),
        ),
        (saved) => saved,
      ),
      'Localização-base atualizada!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), actions: const [ModeIndicatorChip()]),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, session) {
          final profile = session.profile;
          if (profile == null) return const SizedBox.shrink();
          final visible = profile.isVisibleInSearch;

          return ListView(
            children: [
              ProfileCoverHeader(
                profile: profile,
                coverAction: FilledButton.tonalIcon(
                  onPressed: _busy == null ? () => _changePhoto(cover: true) : null,
                  icon: const Icon(Icons.wallpaper, size: 18),
                  label: Text(profile.hasCover ? 'Trocar capa' : 'Adicionar capa'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          visible ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: visible ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visible ? 'Visível nas buscas' : 'Não visível nas buscas',
                            style: TextStyle(
                              color: visible ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _open(const EditProfessionalPage()),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _busy == null ? () => _changePhoto(cover: false) : null,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Trocar foto de perfil'),
                    ),
                    if (_busy != null) const LinearProgressIndicator(),

                    // TEL17-E1: o que falta para aparecer nas buscas.
                    if (!visible) ...[
                      const SizedBox(height: 8),
                      AppBanner.warning(
                        !profile.hasLocation
                            ? 'Seu perfil ainda não aparece nas buscas. Falta confirmar a localização-base.'
                            : 'Seu perfil ainda não aparece nas buscas. Falta concluir o perfil profissional.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        style: AppTheme.highlightButton,
                        onPressed: !profile.hasLocation && profile.hasLocationConsent
                            ? _changeLocation
                            : () => _open(const ProfessionalOnboardingPage()),
                        icon: const Icon(Icons.place),
                        label: Text(
                          !profile.hasLocation && profile.hasLocationConsent
                              ? 'Definir localização'
                              : 'Concluir perfil profissional',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ---- Especialidades ------------------------------------------
                    _SectionCard(
                      title: 'ESPECIALIDADES',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final role in [
                            if (profile.primaryRole?.isNotEmpty ?? false) profile.primaryRole!,
                            ...profile.secondarySkills,
                          ])
                            Chip(label: Text(role)),
                          if (!(profile.primaryRole?.isNotEmpty ?? false))
                            Text('Nenhuma ainda', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),

                    // ---- Localização-base ----------------------------------------
                    _SectionCard(
                      icon: Icons.place,
                      title: 'LOCALIZAÇÃO-BASE',
                      subtitle: profile.hasLocation
                          ? (profile.locationLabel.isEmpty
                              ? 'Ponto definido no mapa'
                              : profile.locationLabel)
                          : 'Não definida',
                      action: OutlinedButton(
                        onPressed: _busy == null ? _changeLocation : null,
                        child: const Text('Alterar'),
                      ),
                    ),

                    // ---- Portfólio --------------------------------------------------
                    _SectionCard(
                      icon: Icons.link,
                      title: 'PORTFÓLIO',
                      subtitle: _portfolioCount == null
                          ? '...'
                          : _portfolioCount == 1
                              ? '1 item'
                              : '$_portfolioCount itens',
                      action: OutlinedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ManagePortfolioPage()),
                          );
                          _loadPortfolioCount();
                        },
                        child: const Text('Gerenciar'),
                      ),
                    ),

                    // ---- Currículo (extra do app) -------------------------------
                    _SectionCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'CURRÍCULO',
                      subtitle: profile.hasResume ? 'PDF enviado' : 'Nenhum PDF enviado',
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (profile.hasResume)
                            TextButton(onPressed: _openResume, child: const Text('Ver')),
                          OutlinedButton(
                            onPressed: _busy == null ? _uploadResume : null,
                            child: Text(profile.hasResume ? 'Trocar' : 'Enviar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _open(PublicProfilePage(userId: profile.id)),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver como os contratantes veem'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cartão de seção: rótulo em caixa alta + conteúdo ou subtítulo + ação.
class _SectionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? action;

  const _SectionCard({this.icon, required this.title, this.subtitle, this.child, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodyMedium),
                  ?child,
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
