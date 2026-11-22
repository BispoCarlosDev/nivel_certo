import 'package:flutter/material.dart';
import 'package:nivel_certo/services/auth_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  // Etapa 1: informar o e-mail | Etapa 2: código recebido + nova senha
  int _etapa = 1;
  bool _carregando = false;
  bool _codigoConfirmado = false;
  bool _ocultarSenha = true;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    final email = _emailController.text.trim();
    if (!AuthService.emailValido(email)) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await AuthService.instance.enviarCodigoRecuperacao(email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = AuthService.mensagemDe(e);
      });
      return;
    }
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _etapa = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se o e-mail estiver cadastrado, enviamos um código.'),
      ),
    );
  }

  Future<void> _redefinirSenha() async {
    final nova = _novaSenhaController.text;
    String? erro;
    if (!_codigoConfirmado && _codigoController.text.trim().isEmpty) {
      erro = 'Digite o código recebido por e-mail.';
    } else if (nova.length < 6) {
      erro = 'A senha deve ter pelo menos 6 caracteres.';
    } else if (nova != _confirmarController.text) {
      erro = 'As senhas não conferem.';
    }
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (!_codigoConfirmado) {
        await AuthService.instance.verificarCodigo(
          _emailController.text,
          _codigoController.text,
        );
        _codigoConfirmado = true;
      }
      await AuthService.instance.definirNovaSenha(nova);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = AuthService.mensagemDe(e);
      });
      return;
    }
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Volta para o login
    messenger.showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso! Faça seu login.')),
    );
  }

  InputDecoration _decoracao(String label, {Widget? sufixo}) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: sufixo,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo e nome do app
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Logo_App_NC.png', height: 70),
                  const Text(
                    'Nível Certo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Recuperar Senha',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _etapa == 1
                    ? 'Informe o e-mail cadastrado para receber um código de verificação.'
                    : 'Digite o código recebido por e-mail e escolha sua nova senha.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              if (_etapa == 1)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracao('E-mail'),
                )
              else ...[
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  readOnly: _codigoConfirmado,
                  decoration: _decoracao('Código de verificação'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _novaSenhaController,
                  obscureText: _ocultarSenha,
                  decoration: _decoracao(
                    'Nova Senha',
                    sufixo: IconButton(
                      icon: Icon(
                        _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _ocultarSenha = !_ocultarSenha),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmarController,
                  obscureText: _ocultarSenha,
                  decoration: _decoracao('Confirmar Nova Senha'),
                ),
              ],

              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _carregando
                      ? null
                      : (_etapa == 1 ? _enviarCodigo : _redefinirSenha),
                  child: _carregando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _etapa == 1 ? 'Enviar Código' : 'Redefinir Senha',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),

              if (_etapa == 2)
                TextButton(
                  onPressed: _carregando || _codigoConfirmado
                      ? null
                      : () => setState(() {
                            _etapa = 1;
                            _erro = null;
                          }),
                  child: const Text(
                    'Reenviar código',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Voltar para o Login',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
