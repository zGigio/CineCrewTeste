// =============================================================================
// core/network/supabase_guard.dart
// -----------------------------------------------------------------------------
// "GUARDA" das requisições ao Supabase.
//
// Toda chamada ao back-end pode falhar de vários jeitos (sem internet, senha
// errada, sem permissão...). Em vez de repetir try/catch em cada repositório,
// todos usam a função `guardRequest`, que:
//   1. Executa a requisição;
//   2. Se der certo, devolve Right(resultado);
//   3. Se der errado, converte o erro técnico em uma Failure com mensagem
//      amigável em português e devolve Left(failure).
// =============================================================================

import 'package:fpdart/fpdart.dart' show Either, Left, Right;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Executa [request] e transforma qualquer erro em [Failure].
///
/// `<T>` é um tipo genérico: a mesma função serve para requisições que
/// devolvem um perfil, uma lista de vagas, um texto, etc.
Future<Either<Failure, T>> guardRequest<T>(Future<T> Function() request) async {
  try {
    final result = await request();
    return Right(result);
  } on Failure catch (failure) {
    // Regras de negócio podem lançar uma Failure diretamente.
    return Left(failure);
  } on AuthException catch (e) {
    // Erros de login/cadastro.
    return Left(AuthFailure(_translateAuthMessage(e.message)));
  } on PostgrestException catch (e) {
    // Erros do banco de dados (PostgREST é a API REST do PostgreSQL).
    return Left(ServerFailure(message: _translateDatabaseError(e)));
  } on StorageException catch (e) {
    // Erros ao enviar/baixar arquivos (fotos, currículos).
    return Left(ServerFailure(message: 'Falha ao enviar o arquivo: ${e.message}'));
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    // Sem internet / servidor inacessível: o erro técnico vem em inglês
    // ("SocketException", "Failed host lookup"...). Traduzimos para o usuário.
    if (_isConnectionError(e)) {
      return const Left(
        ServerFailure(
          message: 'Sem conexão com o servidor. Verifique sua internet e tente novamente.',
        ),
      );
    }
    // Qualquer outro erro não previsto.
    return Left(UnexpectedFailure(e.toString()));
  }
}

/// Reconhece erros de rede pelo texto do erro técnico.
bool _isConnectionError(Object error) {
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('Connection refused') ||
      text.contains('TimeoutException');
}

/// Traduz as mensagens (em inglês) do sistema de login do Supabase.
String _translateAuthMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (lower.contains('already registered')) {
    return 'Este e-mail já está cadastrado.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar (verifique sua caixa de entrada).';
  }
  if (lower.contains('password should be at least')) {
    return 'A senha deve ter pelo menos 6 caracteres.';
  }
  return message;
}

/// Mensagem para quando o banco está atrás do app (falta rodar o schema.sql).
const String outdatedSchemaMessage =
    'O banco de dados do Supabase está desatualizado em relação ao app. '
    'Execute o arquivo supabase/schema.sql mais recente no SQL Editor do Supabase.';

/// Traduz os códigos de erro do PostgreSQL mais comuns.
/// Lista oficial de códigos: https://www.postgresql.org/docs/current/errcodes-appendix.html
String _translateDatabaseError(PostgrestException e) {
  // Às vezes o erro chega sem `code` e com o JSON inteiro na mensagem
  // ({"code":"42703",...}). Procuramos o código também dentro do texto.
  final code = e.code ??
      RegExp(r'"code"\s*:\s*"([A-Z0-9]+)"').firstMatch(e.message)?.group(1);
  switch (code) {
    case '23505': // unique_violation: registro duplicado
      return 'Este registro já existe (ex.: você já se candidatou a esta vaga).';
    case '42501': // insufficient_privilege: bloqueado pelas regras de RLS
    case '23514': // check_violation: dado fora das regras da tabela
      // Os gatilhos do nosso banco já mandam mensagens em português
      // (ex.: "Apenas o contratante da vaga pode..."): mostramos como vieram.
      // As mensagens padrão do PostgreSQL vêm em inglês: trocamos por uma genérica.
      final isDefaultEnglishMessage = e.message.startsWith('new row') ||
          e.message.startsWith('permission denied') ||
          e.message.contains('violates');
      if (!isDefaultEnglishMessage) return e.message;
      return e.code == '42501'
          ? 'Você não tem permissão para realizar esta ação.'
          : 'Dados inválidos: verifique os campos preenchidos.';
    case 'PGRST116': // .single() não encontrou nenhuma linha
      return 'Registro não encontrado.';
    // Coluna, tabela ou função que o app usa e não existe no Supabase:
    // o schema.sql mais recente não foi executado no projeto.
    case '42703': // coluna não existe
    case '42P01': // tabela não existe
    case '42883': // função não existe
    case 'PGRST202': // função (RPC) não encontrada
    case 'PGRST204': // coluna não encontrada
      return '$outdatedSchemaMessage\n(Detalhe técnico: ${e.message})';
    default:
      return e.message;
  }
}
