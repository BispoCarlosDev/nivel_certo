import 'package:flutter/material.dart';

class CadastroCaixaScreen extends StatefulWidget {
  // Quando recebe uma caixa, a tela funciona como edição
  final Map<String, String>? caixa;

  const CadastroCaixaScreen({super.key, this.caixa});

  @override
  State<CadastroCaixaScreen> createState() => _CadastroCaixaScreenState();
}

class _CadastroCaixaScreenState extends State<CadastroCaixaScreen> {
  late final _nomeController = TextEditingController(text: widget.caixa?['nome']);
  late final _marcaController = TextEditingController(text: widget.caixa?['marca']);
  late final _tamanhoController = TextEditingController(text: widget.caixa?['tamanho']);
  late final _modeloController = TextEditingController(text: widget.caixa?['modelo']);

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _tamanhoController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final caixa = widget.caixa;
    if (caixa == null) {
      Navigator.pop(context);
      return;
    }
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da caixa.')),
      );
      return;
    }
    Navigator.pop(context, {...caixa, 'nome': nome});
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
              // Adicionando Logo e Nome do App
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

              // Inserindo o título da Tela Cadastrar Caixas Dagua
              Text(
                widget.caixa == null
                    ? 'Cadastrar Caixa D\'Água'
                    : 'Editar Caixa D\'Água',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),

              // Inserindo um container e um botão para sincronizar dispositivos
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
                        backgroundColor: const Color(0xFF0D47A1),
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

              // Inserindo o campo Nome da Caixa
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Caixa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Inserindo o campo marca da Caixa
              TextField(
                controller: _marcaController,
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

              // Inserindo o campo de tamanho da caixa
              TextField(
                controller: _tamanhoController,
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

              // Inserindo o modelo da caixa
              TextField(
                controller: _modeloController,
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

              // Inserindo o botão de confirmar
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
                  onPressed: _confirmar,
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
              const SizedBox(height: 4),

              // Inserindo o textbutto de cancelar
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Volta para a tela anterior
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
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
