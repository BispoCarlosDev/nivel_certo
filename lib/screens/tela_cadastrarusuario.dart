import 'package:flutter/material.dart';

class CadastroUsuarioScreen extends StatelessWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo_App_NC.png',
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nível Certo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Cadastrar Usuário',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(InputDecoration)
            ],
          ),
        ),
      ),
    );
  }
}