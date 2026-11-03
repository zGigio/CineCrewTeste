// =============================================================================
// modules/profile/domain/entities/user_profile.dart
// -----------------------------------------------------------------------------
// ENTIDADE do PERFIL do usuário (camada de DOMÍNIO).
//
// Cada pessoa tem UMA conta, que pode ter um ou dois PAPÉIS (como no Airbnb,
// em que o hóspede pode "tornar-se anfitrião"):
//   * Profissional: oferece seus serviços e se candidata a vagas;
//   * Contratante: publica vagas e seleciona profissionais.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Perfil completo de um usuário do Banco de Talentos.
class UserProfile extends Equatable {
  /// Identificador único (o mesmo da conta de login no Supabase).
  final String id;

  /// Nome completo.
  final String fullName;

  /// E-mail de cadastro.
  final String? email;

  /// Telefone / WhatsApp de contato.
  final String? phone;

  /// Papel "profissional": oferece serviços e se candidata a vagas.
  final bool isProfessional;

  /// Papel "contratante": publica vagas e seleciona profissionais.
  final bool isRecruiter;

  /// Função principal (ex.: "Videomaker"). Usada pelos profissionais.
  final String? primaryRole;

  /// Habilidades extras (ex.: ["Drone", "Edição"]).
  final List<String> secondarySkills;

  /// Apresentação / mini-currículo em texto.
  final String? bio;

  /// URL pública da foto de perfil.
  final String? avatarUrl;

  /// Caminho do PDF do currículo no armazenamento (pasta privada).
  final String? resumePath;

  /// Nome da produtora/empresa (usado pelos contratantes).
  final String? companyName;

  /// Cidade e estado (UF).
  final String? city;
  final String? state;

  /// Coordenadas geográficas (GPS) da base do usuário.
  /// São elas que permitem a busca por raio (computação espacial).
  final double? latitude;
  final double? longitude;

  /// Avaliação média (0 a 5).
  final double rating;

  /// Quantidade de avaliações recebidas.
  final int reviewsCount;

  /// "Título profissional" abaixo do nome, como no LinkedIn
  /// (ex.: "Videomaker de casamentos · 8 anos de set").
  final String? headline;

  /// URL pública da foto de CAPA (topo do perfil).
  final String? coverUrl;

  /// POSIÇÃO APROXIMADA (grade de ~1,1 km), a única visível para os outros.
  final double? approxLatitude;
  final double? approxLongitude;

  /// Conta desativada pela pessoa (TEL22). `null` = ativa.
  final DateTime? deactivatedAt;

  /// Último modo usado ('professional' ou 'recruiter'), para abrir nele (P20).
  final String? lastMode;

  /// Data do aceite do uso da localização (LGPD). Só é carregada no perfil
  /// do PRÓPRIO usuário; `null` = ainda não aceitou (ou revogou).
  final DateTime? locationConsentAt;

  /// Profissional disponível para novos trabalhos?
  final bool isAvailable;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.isProfessional = true,
    this.isRecruiter = false,
    this.primaryRole,
    this.secondarySkills = const [],
    this.bio,
    this.avatarUrl,
    this.resumePath,
    this.companyName,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.reviewsCount = 0,
    this.headline,
    this.coverUrl,
    this.approxLatitude,
    this.approxLongitude,
    this.locationConsentAt,
    this.deactivatedAt,
    this.lastMode,
    this.isAvailable = true,
  });

  // ---------------------------------------------------------------------------
  // Atalhos (getters) calculados a partir dos campos acima.
  // ---------------------------------------------------------------------------

  /// O usuário já informou a localização?
  bool get hasLocation => latitude != null && longitude != null;

  /// O usuário já enviou um currículo?
  bool get hasResume => resumePath != null && resumePath!.isNotEmpty;

  /// O usuário já tem foto de perfil?
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Há posição aproximada (perfil de outra pessoa)?
  bool get hasApproxLocation => approxLatitude != null && approxLongitude != null;

  /// A conta está desativada?
  bool get isDeactivated => deactivatedAt != null;

  /// O usuário aceitou o uso da localização? Sem aceite não aparece nas buscas.
  bool get hasLocationConsent => locationConsentAt != null;

  /// Perfil profissional pronto para aparecer nas buscas (RN13): função,
  /// localização-base e aceite em vigor.
  bool get isVisibleInSearch =>
      isProfessional &&
      primaryRole != null &&
      primaryRole!.isNotEmpty &&
      hasLocation &&
      hasLocationConsent;

  /// O usuário já escolheu uma foto de capa?
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// A conta já ativou algum perfil? Conta recém-criada ainda não tem
  /// nenhum e passa pela tela "Como você quer começar?" (TEL04).
  bool get hasAnyRole => isProfessional || isRecruiter;

  /// O usuário tem os DOIS papéis (pode alternar entre os modos)?
  bool get hasBothRoles => isProfessional && isRecruiter;

  /// Primeiro nome, para saudações ("Olá, Leonardo").
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.first.isEmpty ? 'usuário' : parts.first;
  }

  /// "Cidade - UF" (ou só o que estiver preenchido).
  String get locationLabel => [city, state]
      .where((part) => part != null && part.isNotEmpty)
      .join(' - ');

  /// Cria uma CÓPIA do perfil trocando apenas os campos informados.
  /// (Objetos imutáveis não são alterados: geramos uma nova versão.)
  UserProfile copyWith({
    String? fullName,
    String? phone,
    bool? isProfessional,
    bool? isRecruiter,
    String? primaryRole,
    List<String>? secondarySkills,
    String? bio,
    String? avatarUrl,
    String? resumePath,
    String? companyName,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    String? headline,
    String? coverUrl,
    DateTime? locationConsentAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      rating: rating,
      reviewsCount: reviewsCount,
      headline: headline ?? this.headline,
      coverUrl: coverUrl ?? this.coverUrl,
      approxLatitude: approxLatitude,
      approxLongitude: approxLongitude,
      locationConsentAt: locationConsentAt ?? this.locationConsentAt,
      deactivatedAt: deactivatedAt,
      lastMode: lastMode,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isProfessional: isProfessional ?? this.isProfessional,
      isRecruiter: isRecruiter ?? this.isRecruiter,
      primaryRole: primaryRole ?? this.primaryRole,
      secondarySkills: secondarySkills ?? this.secondarySkills,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      resumePath: resumePath ?? this.resumePath,
      companyName: companyName ?? this.companyName,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        isProfessional,
        isRecruiter,
        primaryRole,
        secondarySkills,
        bio,
        avatarUrl,
        resumePath,
        companyName,
        city,
        state,
        latitude,
        longitude,
        rating,
        reviewsCount,
        headline,
        coverUrl,
        approxLatitude,
        approxLongitude,
        locationConsentAt,
        deactivatedAt,
        lastMode,
        isAvailable,
      ];
}
