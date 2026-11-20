import 'package:flutter/material.dart';
import 'package:nivel_certo/models/usuario.dart';
import 'package:nivel_certo/services/auth_service.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _nomeController = TextEditingController();
  final _dataController = TextEditingController();
  final _generoController = TextEditingController();
  final _contatoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _generos = const ['Feminino', 'Masculino', 'Outro', 'Prefiro não informar'];
  DateTime? _dataNascimento;
  bool _ocultarSenha = true;
  bool _ocultarConfirmar = true;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _dataController.dispose();
    _generoController.dispose();
    _contatoController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(hoje.year - 18, hoje.month, hoje.day),
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Data de nascimento',
    );
    if (data == null || !mounted) return;
    _dataNascimento = data;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    _dataController.text = '$dia/$mes/${data.year}';
  }

  Future<void> _selecionarGenero() async {
    final genero = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gênero',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            for (final opcao in _generos)
              ListTile(
                title: Text(opcao),
                trailing: opcao == _generoController.text
                    ? const Icon(Icons.check, color: Color(0xFF0D47A1))
                    : null,
                onTap: () => Navigator.pop(context, opcao),
              ),
          ],
        ),
      ),
    );
    if (genero != null) _generoController.text = genero;
  }

  void _cadastrar() {
    final nome = _nomeController.text.trim();
    final contato = _contatoController.text.trim();
    final senha = _senhaController.text;

    String? erro;
    if (nome.isEmpty || contato.isEmpty || senha.isEmpty) {
      erro = 'Preencha nome, e-mail ou celular e senha.';
    } else if (!AuthService.contatoValido(contato)) {
      erro = 'Informe um e-mail válido ou um celular com DDD.';
    } else if (senha.length < 6) {
      erro = 'A senha deve ter pelo menos 6 caracteres.';
    } else if (senha != _confirmarController.text) {
      erro = 'As senhas não conferem.';
    } else if (AuthService.instance.contatoExiste(contato)) {
      erro = 'Já existe uma conta com esse e-mail ou celular.';
    }

    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    AuthService.instance.cadastrar(
      Usuario(
        nome: nome,
        dataNascimento: _dataController.text.trim(),
        genero: _generoController.text,
        contato: contato,
        senha: senha,
      ),
    );

    // Após cadastrar, volta para a tela de login
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Cadastro realizado! Faça seu login.')),
    );
  }

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
              // Adicionando o logo e o nome do app
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo_App_NC.png',
                    height: 70,
                  ),
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
              // Inserindo o título da tela "Cadastrar Usuário"
              const Text(
                'Cadastrar Usuário',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),
              // Inserindo o campo para o nome
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Inserindo o campo para selecionar a data de nascimento
              TextField(
                controller: _dataController,
                readOnly: true,
                onTap: _selecionarData,
                decoration: InputDecoration(
                  labelText: 'Data de Nascimento',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Inserindo o campo para selecionar o gênero
              TextField(
                controller: _generoController,
                readOnly: true,
                onTap: _selecionarGenero,
                decoration: InputDecoration(
                  labelText: 'Gênero',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
              const SizedBox(height: 16),
              // Inserindo o campo para inserir o e-mail ou celular
              TextField(
                controller: _contatoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail ou Celular',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Inserindo o campo para a senha
              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              //Inserindo o campo Confirmar Senha
              TextField(
                controller: _confirmarController,
                obscureText: _ocultarConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmar ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarConfirmar = !_ocultarConfirmar),
                  ),
                ),
              ),
              // Mensagem de erro do cadastro (aparece só quando necessário)
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              // Inserindo o botão Cadastrar-se
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
                  onPressed: _cadastrar,
                  child: const Text(
                    'Cadastrar-se',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Inserindo o texto clicável para Fazer login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Já tem conta? Fazer Login',
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