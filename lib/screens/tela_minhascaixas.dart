import 'package:flutter/material.dart';
import 'package:nivel_certo/screens/tela_cadastrarcaixa.dart';
import 'package:nivel_certo/screens/tela_niveldeagua.dart';

class MinhasCaixasScreen extends StatefulWidget {
  const MinhasCaixasScreen({super.key});

  @override
  State<MinhasCaixasScreen> createState() => _MinhasCaixasScreenState();
}

class _MinhasCaixasScreenState extends State<MinhasCaixasScreen> {
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
                child: _caixas.isNotEmpty
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroCaixaScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Abre a tela de cadastro com os dados da caixa para edição
  Future<void> _editarCaixa(Map<String, String> caixa) async {
    final atualizada = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroCaixaScreen(caixa: caixa),
      ),
    );
    if (atualizada != null) {
      setState(() {
        final index = _caixas.indexOf(caixa);
        if (index != -1) _caixas[index] = atualizada;
      });
    }
  }

  // Pede confirmação antes de excluir a caixa
  Future<void> _confirmarExclusao(Map<String, String> caixa) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir caixa'),
        content: Text(
          'Deseja realmente excluir a caixa "${caixa['nome']}"? '
          'Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      setState(() => _caixas.remove(caixa));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa excluída.')),
      );
    }
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
                // Ação ao clicar no card da caixa: abre a tela de nível de água.
                // O tamanho vem como texto (ex: '500L'), então extraímos só os números.
                final capacidade = double.parse(
                  caixa['tamanho']!.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NivelAguaScreen(
                      nomeCaixa: caixa['nome']!,
                      capacidadeTotal: capacidade,
                    ),
                  ),
                );
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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (opcao) {
                        if (opcao == 'editar') {
                          _editarCaixa(caixa);
                        } else {
                          _confirmarExclusao(caixa);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
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
