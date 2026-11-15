import 'package:flutter/material.dart';

class MinhasCaixasScreen extends StatefulWidget {
  const MinhasCaixasScreen({super.key});

  @override
  State<MinhasCaixasScreen> createState() => _MinhasCaixasScreenState();
}

class _MinhasCaixasScreenState extends State<MinhasCaixasScreen> {
  // Variável para alternar entre o estado vazio (false) e com caixas cadastradas (true) para teste visual
  bool _temCaixas = true;

  // Exemplo de lista de dados para preencher os cards das caixas D'Água
  final _caixas = [
    {
      'codigo': '001',
      'nome': 'Caixa Principal',
      'marca': 'Genérica',
      'modelo': 'Redonda',
      'tamanho': '500L',
    },
    {
      'codigo': '002',
      'nome': 'Caixa dos Fundos',
      'marca': 'Fortlev',
      'modelo': 'Redonda',
      'tamanho': '500L',
    },
    {
      'codigo': '003',
      'nome': 'Caixa Reserva',
      'marca': 'Infibra',
      'modelo': 'Redonda',
      'tamanho': '1000L',
    },
    {
      'codigo': '004',
      'nome': 'Caixa Reserva',
      'marca': 'Infibra',
      'modelo': 'Redonda',
      'tamanho': '1000L',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Inserindo a Logo e o nome do App
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

              // Título da Tela Minhas Caixas D'Água
              const Text(
                'Minhas Caixas D\'Água',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),

              // Seleção de Opções Com Caixas ou sem Caixas
              Expanded(
                child: _temCaixas
                    ? _construirListaCaixas()
                    : _construirEstadoVazio(),
              ),
            ],
          ),
        ),
      ),
      // Botão Flutuante de Adicionar Caixa no canto inferior direito
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        shape: const CircleBorder(
          side: BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        onPressed: () {
          // Ação para navegar até a tela de Cadastro de Caixa (CadastroCaixaScreen)
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Widget para o estado quando NÃO HÁ caixas cadastradas
  Widget _construirEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 20.0,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/caixa.png',
              height: 220,
            ),
            const SizedBox(height: 16),
            const Text(
              'Não há Caixas D\'Água Cadastradas.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para o estado com caixas cadastradas em formato de Cards
  Widget _construirListaCaixas() {
    return ListView.builder(
      itemCount: _caixas.length,
      itemBuilder: (context, index) {
        final caixa = _caixas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Ação ao clicar no card da caixa (ex: abrir a tela de nível da água)
                print('Clicou na caixa: ${caixa['nome']}');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código: ${caixa['codigo']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nome: ${caixa['nome']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Marca: ${caixa['marca']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modelo: ${caixa['modelo']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tamanho: ${caixa['tamanho']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // Ação ao clicar nos três pontos
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
