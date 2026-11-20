import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nivel_certo/services/auth_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _contatoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  // Etapa 1: informar e-mail/celular | Etapa 2: código + nova senha
  int _etapa = 1;
  String _codigoGerado = '';
  String? _erro;

  @override
  void dispose() {
    _contatoController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _enviarCodigo() {
    final contato = _contatoController.text;
    if (contato.trim().isEmpty) {
      setState(() => _erro = 'Informe seu e-mail ou celular.');
      return;
    }
    if (!AuthService.instance.contatoExiste(contato)) {
      setState(() => _erro = 'Não encontramos uma conta com esse e-mail ou celular.');
      return;
    }

    // Gera um código de 6 dígitos
    _codigoGerado = (Random().nextInt(900000) + 100000).toString();
    setState(() {
      _erro = null;
      _etapa = 2;
    });

    // PROTÓTIPO: como não há e-mail/SMS de verdade, mostramos o código na tela.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de verificação'),
        content: Text(
          'Seu código é $_codigoGerado\n\n'
          '(Simulação: em um app real, ele seria enviado por e-mail ou SMS.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _redefinirSenha() {
    final nova = _novaSenhaController.text;
    String? erro;
    if (_codigoController.text.trim() != _codigoGerado) {
      erro = 'Código incorreto.';
    } else if (nova.length < 6) {
      erro = 'A senha deve ter pelo menos 6 caracteres.';
    } else if (nova != _confirmarController.text) {
      erro = 'As senhas não conferem.';
    }
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    AuthService.instance.redefinirSenha(_contatoController.text, nova);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Volta para o login
    messenger.showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso! Faça seu login.')),
    );
  }

  InputDecoration _decoracao(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    ? 'Informe o e-mail ou celular cadastrado para receber um código de verificação.'
                    : 'Digite o código recebido e escolha sua nova senha.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              if (_etapa == 1)
                TextField(
                  controller: _contatoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracao('E-mail ou Celular'),
                )
              else ...[
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  decoration: _decoracao('Código de verificação'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _novaSenhaController,
                  obscureText: true,
                  decoration: _decoracao('Nova Senha'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmarController,
                  obscureText: true,
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
                  onPressed: _etapa == 1 ? _enviarCodigo : _redefinirSenha,
                  child: Text(
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
