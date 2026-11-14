import 'package:flutter/material.dart';

class CadastroCaixaScreen extends StatelessWidget {
  const CadastroCaixaScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo_App_NC.png',
                    height: 70,
                  ),
                  const SizedBox(width: 12),
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

              // Título da Tela
              const Text(
                'Cadastrar Caixa D\'Água',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),

              // (Continuando dentro da Column:)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sincronizar com\nDispositivo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1), // Azul escuro
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Ação para buscar/conectar com o dispositivo ESP32 depois
                      },
                      icon: const Icon(
                        Icons.sync,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Buscar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // (Continuando dentro da Column:)

              // Nome da Caixa
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nome da Caixa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Marca Caixa D'Água (Simulando o select com seta)
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Marca Caixa D\'Água',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
              const SizedBox(height: 16),

              // Tamanho (Litros)
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tamanho (Litros)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
              const SizedBox(height: 16),

              // Modelo
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
              const SizedBox(height: 24),

              // (Finalizando dentro da Column:)

              // Botão Confirmar
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
                  onPressed: () {
                    // Ação de confirmar o cadastro da caixa
                  },
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Link Cancelar
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Volta para a tela anterior
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
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
