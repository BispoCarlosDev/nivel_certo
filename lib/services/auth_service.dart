import 'package:nivel_certo/models/usuario.dart';

/// Serviço de autenticação do PROTÓTIPO.
/// Os usuários ficam guardados apenas na memória: ao fechar o app, eles somem.
/// Quando o backend existir, só este arquivo precisa ser trocado.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final List<Usuario> _usuarios = [];

  // E-mail: minúsculo e sem espaços. Celular: somente os números.
  // Assim "(69) 99999-0000" e "69999990000" são tratados como o mesmo contato.
  static String normalizar(String contato) {
    final c = contato.trim();
    return c.contains('@') ? c.toLowerCase() : c.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool contatoValido(String contato) {
    final c = contato.trim();
    if (c.contains('@')) {
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(c);
    }
    final digitos = c.replaceAll(RegExp(r'[^0-9]'), '');
    return digitos.length == 10 || digitos.length == 11; // DDD + número
  }

  Usuario? _buscar(String contato) {
    final chave = normalizar(contato);
    for (final u in _usuarios) {
      if (normalizar(u.contato) == chave) return u;
    }
    return null;
  }

  bool contatoExiste(String contato) => _buscar(contato) != null;

  void cadastrar(Usuario usuario) => _usuarios.add(usuario);

  bool login(String contato, String senha) {
    final u = _buscar(contato);
    return u != null && u.senha == senha;
  }

  bool redefinirSenha(String contato, String novaSenha) {
    final u = _buscar(contato);
    if (u == null) return false;
    u.senha = novaSenha;
    return true;
  }
}
