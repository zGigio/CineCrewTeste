// =============================================================================
// modules/profile/domain/repositories/profile_repository.dart
// -----------------------------------------------------------------------------
// CONTRATO do repositório de PERFIS (camada de DOMÍNIO).
//
// Define O QUE pode ser feito com um perfil, sem dizer COMO (isso fica na
// implementação, que usa o Supabase).
// =============================================================================

import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// Operações disponíveis sobre perfis de usuário.
abstract class ProfileRepository {
  /// Busca o perfil do usuário com o [userId] informado.
  Future<Either<Failure, UserProfile>> getProfile(String userId);

  /// Salva as alterações do perfil e devolve a versão gravada no banco.
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile);

  /// Envia a FOTO de perfil ([bytes] = conteúdo da imagem) e devolve a URL
  /// pública dela, já gravada no perfil.
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  });

  /// Envia a foto de CAPA (topo do perfil, estilo LinkedIn) e devolve a URL
  /// pública dela, já gravada no perfil.
  Future<Either<Failure, String>> uploadCover({
    required String userId,
    required Uint8List bytes,
  });

  /// Envia o CURRÍCULO em PDF e devolve o caminho dele no armazenamento,
  /// já gravado no perfil.
  Future<Either<Failure, String>> uploadResume({
    required String userId,
    required Uint8List bytes,
  });

  /// Guarda o último modo usado ('professional' ou 'recruiter'), para o app
  /// abrir nele no próximo login (pendência P20).
  Future<Either<Failure, Unit>> saveLastMode(String userId, String mode);

  /// Registra o ACEITE do uso da localização (LGPD, TEL07) com a versão do
  /// texto aceito. Devolve a data/hora do aceite em vigor.
  Future<Either<Failure, DateTime>> acceptLocationTerms(String termsVersion);

  /// Gera um link TEMPORÁRIO (válido por 1 hora) para abrir o currículo.
  /// Como a pasta de currículos é privada, o arquivo não tem link fixo.
  Future<Either<Failure, String>> getResumeUrl(String resumePath);
}
