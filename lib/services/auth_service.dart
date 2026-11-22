import 'package:supabase_flutter/supabase_flutter.dart';

class EmailJaCadastradoException implements Exception {
  const EmailJaCadastradoException();
}

// Autenticação pelo Supabase Auth (e-mail e senha).
// A senha é guardada com hash pelo próprio Supabase.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  static bool emailValido(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  static String _normalizar(String email) => email.trim().toLowerCase();

  bool get logado => _auth.currentSession != null;

  // Retorna true quando o usuário precisa confirmar o e-mail antes de entrar
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    DateTime? dataNascimento,
    String genero = '',
  }) async {
    String? nascimento;
    if (dataNascimento != null) {
      final mes = dataNascimento.month.toString().padLeft(2, '0');
      final dia = dataNascimento.day.toString().padLeft(2, '0');
      nascimento = '${dataNascimento.year}-$mes-$dia';
    }

    final resposta = await _auth.signUp(
      email: _normalizar(email),
      password: senha,
      data: {
        'nome': nome,
        'data_nascimento': nascimento ?? '',
        'genero': genero,
      },
    );

    // Com a confirmação de e-mail ligada, um e-mail já cadastrado não gera
    // erro: o Supabase devolve um usuário sem identidades
    if (resposta.user?.identities?.isEmpty ?? false) {
      throw const EmailJaCadastradoException();
    }

    if (resposta.session != null) {
      await _auth.signOut();
      return false;
    }
    return true;
  }

  Future<void> login(String email, String senha) async {
    await _auth.signInWithPassword(
      email: _normalizar(email),
      password: senha,
    );
  }

  Future<void> sair() => _auth.signOut();

  // Envia por e-mail um código de verificação
  Future<void> enviarCodigoRecuperacao(String email) =>
      _auth.resetPasswordForEmail(_normalizar(email));

  Future<void> verificarCodigo(String email, String codigo) async {
    await _auth.verifyOTP(
      email: _normalizar(email),
      token: codigo.trim(),
      type: OtpType.recovery,
    );
  }

  // Deve ser chamado depois de verificarCodigo
  Future<void> definirNovaSenha(String novaSenha) async {
    await _auth.updateUser(UserAttributes(password: novaSenha));
    await _auth.signOut();
  }

  // Traduz erros do Supabase para mensagens que o usuário entende
  static String mensagemDe(Object erro) {
    if (erro is EmailJaCadastradoException) {
      return 'Já existe uma conta com esse e-mail.';
    }
    if (erro is AuthException) {
      switch (erro.code) {
        case 'invalid_credentials':
          return 'E-mail ou senha incorretos.';
        case 'email_not_confirmed':
          return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
        case 'user_already_exists':
        case 'email_exists':
          return 'Já existe uma conta com esse e-mail.';
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
        case 'otp_expired':
          return 'Código inválido ou expirado.';
        case 'weak_password':
          return 'Senha muito fraca. Use pelo menos 6 caracteres.';
        case 'same_password':
          return 'A nova senha deve ser diferente da anterior.';
        case 'validation_failed':
          return 'Informe um e-mail válido.';
      }
    }
    final texto = erro.toString();
    if (texto.contains('SocketException') ||
        texto.contains('ClientException') ||
        texto.contains('Failed host lookup')) {
      return 'Sem conexão com a internet.';
    }
    return 'Não foi possível concluir. Tente novamente.';
  }
}
