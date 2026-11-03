// =============================================================================
// modules/profile/presentation/pages/profile_page.dart
// -----------------------------------------------------------------------------
// TELA "MEU PERFIL".
//
// Seções:
//   1. Capa e foto de perfil (enviadas na hora, ao escolher na galeria),
//      atalho "Ver como os outros veem" e "Portfólio e experiências";
//   2. Papéis: profissional e/ou contratante ("Torne-se um contratante");
//   3. Dados pessoais;
//   4. Perfil profissional (função, habilidades, bio, currículo em PDF);
//   5. Dados de contratante (produtora);
//   6. Localização (GPS) — base da busca por raio;
//   7. Botões "Salvar" e "Sair".
//
// Os campos de texto só são gravados ao tocar em "Salvar". Capa, foto e
// currículo são enviados assim que escolhidos.
// =============================================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/audiovisual_roles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../auth/presentation/cubit/session_state.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../widgets/become_recruiter_card.dart';
import '../../../payments/presentation/widgets/wallet_tile.dart';
import '../../../portfolio/presentation/pages/manage_portfolio_page.dart';
import 'public_profile_page.dart';
import '../../../onboarding/presentation/pages/professional_onboarding_page.dart';
import '../../../onboarding/presentation/pages/recruiter_activation_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Tamanho máximo do currículo: 5 MB (em bytes).
  static const int _maxResumeBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();

  // Repositório e serviço obtidos do GetIt (injeção de dependências).
  final ProfileRepository _repository = getIt<ProfileRepository>();
  final LocationService _locationService = getIt<LocationService>();

  // Controladores dos campos de texto.
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();
  final _bioController = TextEditingController();
  final _headlineController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  /// Perfil como está salvo no banco (atualizado após cada gravação).
  late UserProfile _profile;

  // Valores editáveis que não são texto livre.
  String? _primaryRole;
  bool _isProfessional = true;
  bool _isRecruiter = false;
  bool _isAvailable = true;
  double? _latitude;
  double? _longitude;

  // Indicadores de carregamento de cada ação.
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  bool _isUploadingResume = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // `context.read` pega o cubit sem "escutar" mudanças (só leitura única).
    _profile = context.read<SessionCubit>().state.profile!;
    _fillForm(_profile);
  }

  /// Preenche os campos da tela com os dados do perfil.
  void _fillForm(UserProfile profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phone ?? '';
    // A lista de habilidades vira um texto separado por vírgulas.
    _skillsController.text = profile.secondarySkills.join(', ');
    _bioController.text = profile.bio ?? '';
    _headlineController.text = profile.headline ?? '';
    _companyController.text = profile.companyName ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _primaryRole = profile.primaryRole;
    _isProfessional = profile.isProfessional;
    _isRecruiter = profile.isRecruiter;
    _isAvailable = profile.isAvailable;
    _latitude = profile.latitude;
    _longitude = profile.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
    _headlineController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  /// Atualiza o perfil em memória e avisa o SessionCubit (o resto do app,
  /// como o checklist do Início, é redesenhado com os dados novos).
  void _applySavedProfile(UserProfile saved) {
    setState(() => _profile = saved);
    context.read<SessionCubit>().updateProfile(saved);
  }

  // ---------------------------------------------------------------------------
  // AÇÕES
  // ---------------------------------------------------------------------------

  /// Salva os dados digitados no formulário.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Regra de negócio: pelo menos um papel ativo.
    if (!_isProfessional && !_isRecruiter) {
      showAppMessage(
        context,
        'Mantenha pelo menos um papel ativo: profissional ou contratante.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    // Converte "Drone, Edição , " em ["Drone", "Edição"].
    final skills = _skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    // Gera uma nova versão do perfil com os valores da tela.
    // Campos vazios ('') são gravados como nulos pelo modelo.
    final updated = _profile.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text,
      isProfessional: _isProfessional,
      isRecruiter: _isRecruiter,
      primaryRole: _primaryRole ?? '',
      secondarySkills: skills,
      bio: _bioController.text,
      headline: _headlineController.text,
      companyName: _companyController.text,
      city: _cityController.text,
      state: _stateController.text.toUpperCase(),
      latitude: _latitude,
      longitude: _longitude,
      isAvailable: _isAvailable,
    );

    final result = await _repository.updateProfile(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (saved) {
        _applySavedProfile(saved);
        showAppMessage(context, 'Perfil salvo!');
      },
    );
  }

  /// "Torne-se um contratante": abre a ativação do modo Contratar (TEL09).
  Future<void> _becomeRecruiter() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RecruiterActivationPage()),
    );
  }

  /// Ativar o modo Profissional: sem o fluxo completo (especialidades,
  /// aceite e localização), o perfil não apareceria nas buscas. Por isso
  /// abrimos a ativação em 4 passos (TEL05 a TEL08).
  Future<void> _becomeProfessional() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfessionalOnboardingPage()),
    );
  }

  /// Escolhe uma foto na galeria e envia como foto de perfil.
  Future<void> _changeAvatar() async {
    // `maxWidth` e `imageQuality` reduzem o tamanho do arquivo enviado.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return; // cancelou ou saiu da tela

    setState(() => _isUploadingAvatar = true);
    final bytes = await picked.readAsBytes();
    final result = await _repository.uploadAvatar(userId: _profile.id, bytes: bytes);
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (url) {
        _applySavedProfile(_profile.copyWith(avatarUrl: url));
        showAppMessage(context, 'Foto atualizada!');
      },
    );
  }

  /// Escolhe uma foto na galeria e envia como CAPA (estilo LinkedIn).
  Future<void> _changeCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, // capa é larga: precisa de mais resolução que a foto
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingCover = true);
    final bytes = await picked.readAsBytes();
    final result = await _repository.uploadCover(userId: _profile.id, bytes: bytes);
    if (!mounted) return;
    setState(() => _isUploadingCover = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (url) {
        _applySavedProfile(_profile.copyWith(coverUrl: url));
        showAppMessage(context, 'Capa atualizada!');
      },
    );
  }

  /// Abre o perfil como os OUTROS veem (perfil público).
  void _openPublicProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PublicProfilePage(userId: _profile.id)),
    );
  }

  /// Escolhe um PDF e envia como currículo.
  Future<void> _uploadResume() async {
    // Abre o seletor de arquivos aceitando só PDF.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null || !mounted) return; // cancelou ou saiu da tela

    setState(() => _isUploadingResume = true);
    final bytes = await file.readAsBytes();

    // Regra: currículo de até 5 MB.
    if (bytes.length > _maxResumeBytes) {
      if (!mounted) return;
      setState(() => _isUploadingResume = false);
      showAppMessage(context, 'O PDF deve ter no máximo 5 MB.', isError: true);
      return;
    }

    final result = await _repository.uploadResume(userId: _profile.id, bytes: bytes);
    if (!mounted) return;
    setState(() => _isUploadingResume = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (path) {
        _applySavedProfile(_profile.copyWith(resumePath: path));
        showAppMessage(context, 'Currículo enviado!');
      },
    );
  }

  /// Abre o currículo no visualizador de PDF do celular.
  Future<void> _openResume() async {
    final path = _profile.resumePath;
    if (path == null) return;

    final result = await _repository.getResumeUrl(path);
    if (!mounted) return;

    final url = result.fold<String?>(
      (failure) {
        showAppMessage(context, failure.message, isError: true);
        return null;
      },
      (link) => link,
    );
    if (url == null) return;

    // `externalApplication`: abre fora do app (navegador / leitor de PDF).
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Captura a posição atual pelo GPS e preenche latitude/longitude.
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    final result = await _locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _isLocating = false);

    result.fold(
      (failure) => showAppMessage(context, failure.message, isError: true),
      (position) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        showAppMessage(context, 'Localização capturada. Toque em "Salvar".');
      },
    );
  }

  /// Sai da conta (com confirmação).
  Future<void> _signOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sair da conta',
      message: 'Deseja mesmo sair?',
      confirmLabel: 'Sair',
    );
    if (!confirmed || !mounted) return;
    await context.read<SessionCubit>().signOut();
  }

  // ---------------------------------------------------------------------------
  // INTERFACE
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Garante que a função atual apareça na lista, mesmo que não seja
    // uma das funções padrão (ex.: digitada em uma versão antiga).
    final roleOptions = {
      ...audiovisualRoles,
      if (_primaryRole != null && _primaryRole!.isNotEmpty) _primaryRole!,
    }.toList();

    // Se o perfil mudar FORA desta tela (ex.: ativou um modo pela TEL05 ou
    // TEL09), recarrega o formulário para não salvar dados antigos por cima.
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (previous, current) =>
          current.profile != null &&
          (previous.profile?.isProfessional != current.profile!.isProfessional ||
              previous.profile?.isRecruiter != current.profile!.isRecruiter ||
              previous.profile?.locationConsentAt != current.profile!.locationConsentAt),
      listener: (context, session) => setState(() {
        _profile = session.profile!;
        _fillForm(_profile);
      }),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- 1. CAPA E FOTO -------------------------------------------
            // Capa (estilo LinkedIn): aparece no topo do perfil público.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_profile.hasCover)
                      Image.network(
                        _profile.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                      )
                    else
                      ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _isUploadingCover ? null : _changeCover,
                        icon: _isUploadingCover
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wallpaper_outlined, size: 18),
                        label: Text(_profile.hasCover ? 'Trocar capa' : 'Adicionar capa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    imageUrl: _profile.avatarUrl,
                    name: _profile.fullName,
                    radius: 48,
                  ),
                  // Botão de câmera posicionado no canto inferior direito.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Trocar foto',
                      onPressed: _isUploadingAvatar ? null : _changeAvatar,
                      icon: _isUploadingAvatar
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _profile.email ?? '',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _openPublicProfile,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Ver como os outros veem'),
              ),
            ),
            const SizedBox(height: 8),

            // Perfil estilo LinkedIn: portfólio e experiências.
            Card(
              child: ListTile(
                leading: Icon(Icons.collections_outlined, color: theme.colorScheme.primary),
                title: const Text('Portfólio e experiências'),
                subtitle: const Text('Fotos, vídeos e trabalhos anteriores'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ManagePortfolioPage()),
                ),
              ),
            ),

            // Carteira (pagamentos recebidos e saques): só para profissionais.
            if (_profile.isProfessional) ...[
              const WalletTile(),
              const SizedBox(height: 8),
            ],

            // ----- 2. PAPÉIS ------------------------------------------------
            if (!_profile.isRecruiter) ...[
              BecomeRecruiterCard(onPressed: _becomeRecruiter),
              const SizedBox(height: 8),
            ],
            const _SectionTitle('Como você usa o app'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Profissional'),
              subtitle: const Text('Ofereço meus serviços e me candidato a vagas'),
              value: _isProfessional,
              onChanged: (value) {
                // Ligar pela primeira vez -> fluxo de ativação completo.
                if (value && !_profile.isProfessional) {
                  _becomeProfessional();
                } else {
                  setState(() => _isProfessional = value);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contratante'),
              subtitle: const Text('Publico vagas e seleciono profissionais'),
              value: _isRecruiter,
              onChanged: (value) {
                if (value && !_profile.isRecruiter) {
                  _becomeRecruiter();
                } else {
                  setState(() => _isRecruiter = value);
                }
              },
            ),

            // ----- 3. DADOS PESSOAIS ----------------------------------------
            const _SectionTitle('Dados pessoais'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.requiredField(value, fieldName: 'O nome'),
            ),
            const SizedBox(height: 12),
            // Título profissional, exibido abaixo do nome (como no LinkedIn).
            TextFormField(
              controller: _headlineController,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título profissional',
                hintText: 'Ex.: Videomaker de casamentos · 8 anos de set',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp',
                hintText: '(21) 99999-9999',
                border: OutlineInputBorder(),
              ),
            ),

            // ----- 4. PERFIL PROFISSIONAL (só se o papel estiver ativo) -----
            if (_isProfessional) ...[
              const _SectionTitle('Perfil profissional'),
              // Lista suspensa com as funções padronizadas.
              DropdownButtonFormField<String>(
                initialValue: _primaryRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Função principal',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final role in roleOptions)
                    DropdownMenuItem(value: role, child: Text(role)),
                ],
                onChanged: (value) => setState(() => _primaryRole = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Outras habilidades',
                  hintText: 'Ex.: Drone, Edição, Colorização',
                  helperText: 'Separe por vírgulas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Sobre você',
                  hintText: 'Experiência, equipamentos, trabalhos de destaque...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponível para trabalhos'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              // Currículo em PDF.
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(
                    _profile.hasResume ? 'Currículo enviado' : 'Nenhum currículo enviado',
                  ),
                  subtitle: const Text('Arquivo PDF de até 5 MB'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_profile.hasResume)
                        IconButton(
                          tooltip: 'Ver currículo',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: _openResume,
                        ),
                      IconButton(
                        tooltip: 'Enviar PDF',
                        onPressed: _isUploadingResume ? null : _uploadResume,
                        icon: _isUploadingResume
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ----- 5. CONTRATANTE (só se o papel estiver ativo) ------------
            if (_isRecruiter) ...[
              const _SectionTitle('Contratante'),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Produtora / empresa (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // ----- 6. LOCALIZAÇÃO ------------------------------------------
            const _SectionTitle('Localização'),
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
                      counterText: '', // esconde o contador "0/2"
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mostra as coordenadas atuais (ou um aviso se não houver).
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _latitude != null ? Icons.location_on : Icons.location_off_outlined,
              ),
              title: Text(
                _latitude != null
                    ? 'Localização definida'
                    : 'Localização não definida',
              ),
              subtitle: Text(
                _latitude != null
                    ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                    : 'Necessária para aparecer nas buscas por raio',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar minha localização atual'),
            ),
            const SizedBox(height: 24),

            // ----- 7. SALVAR -----------------------------------------------
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar perfil'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Título de seção do formulário (pequeno widget reutilizado).
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
