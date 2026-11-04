import 'package:flutter/material.dart';
import 'package:nivel_certo/screens/tela_cadastrarusuario.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

              // SizedBox para afastar o nome do campo de email ou telefone
              const SizedBox(height: 40),

              // Adicionando o campo para preencher o email ou telefone
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail ou Telefone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),

              // SizedBox para agastar o campo de email ou telefone do campo de senha
              const SizedBox(height: 16),

              // Adicionando o campo de senha
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off),
                ),
              ),

              // SizedBox para distanciar o campo de senha do textbutton de esquecer a senha
              const SizedBox(height: 8),

              // Adicionando um TextButton para a opção "Esqueci minha senha"
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {

                  },
                  child: const Text(
                    'Esqueci Minha Senha',
                    style: TextStyle(
                      color: Color(0xFF0F47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

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
                  onPressed: () {

                  },
                  child: const Text(
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
              const SizedBox(height: 16),

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