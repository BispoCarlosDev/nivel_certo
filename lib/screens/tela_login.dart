import 'package:flutter/material.dart';
import 'package:nivel_certo/screens/tela_cadastrarusuario.dart';
import 'package:nivel_certo/screens/tela_minhascaixas.dart';
import 'package:nivel_certo/screens/tela_recuperarsenha.dart';
import 'package:nivel_certo/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Só entra quem está cadastrado e informou a senha correta
  Future<void> _entrar() async {
    final email = _loginController.text.trim();
    final senha = _senhaController.text;
    if (email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail e sua senha.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await AuthService.instance.login(email, senha);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = AuthService.mensagemDe(e);
      });
      return;
    }
    if (!mounted) return;

    // Vai para Minhas Caixas D'Água e remove o login da pilha,
    // assim o botão voltar não retorna para a tela de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MinhasCaixasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              // Adicionando um SizedBox para distanciar o logo do topo da tela
              const SizedBox(height: 20),

              // Adicionando o Logo do aplicativo
              Image.asset(
                'assets/images/Logo_App_NC.png',
                height: 120,
              ),

              // Adicionando o nome do app abaixo do Logo
              const Text(
                'Nível Certo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF0D47A1),
                ),
              ),

              // SizedBox para afastar o nome do campo de e-mail
              const SizedBox(height: 40),

              // Adicionando o campo para preencher o e-mail
              TextField(
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),

              // SizedBox para afastar o campo de e-mail do campo de senha
              const SizedBox(height: 16),

              // Adicionando o campo de senha
              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
              ),

              // SizedBox para distanciar o campo de senha do textbutton de esquecer a senha
              const SizedBox(height: 8),

              // Adicionando um TextButton para a opção "Esqueci minha senha"
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecuperarSenhaScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Esqueci Minha Senha',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0F47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Mensagem de erro de login (aparece só quando necessário)
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],

              // SizedBox para afastar o textbutton de esqueci a senha do botão de entrar
              const SizedBox(height: 24),

              // Adicionando o botão "Entrar"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _carregando ? null : _entrar,
                  child: _carregando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // SizedBox para afastar o botão Entrar do textbutton Criar Conta
              const SizedBox(height: 4),

              // Adicionando o TextButton Criar Conta
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CadastroUsuarioScreen()),
                  );
                },
                child: const Text(
                  'Criar Conta',
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