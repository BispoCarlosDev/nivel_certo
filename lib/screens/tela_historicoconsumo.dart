import 'package:flutter/material.dart';

class HistoricoConsumoScreen extends StatefulWidget {
  final String nomeCaixa;
  final double capacidadeTotal;

  const HistoricoConsumoScreen({
    super.key,
    this.nomeCaixa = 'Nome da Caixa',
    this.capacidadeTotal = 1000.0,
  });

  @override
  State<HistoricoConsumoScreen> createState() => _HistoricoConsumoScreenState();
}

class _HistoricoConsumoScreenState extends State<HistoricoConsumoScreen> {
  // Estado da Semana Selecionada (Ex: Semana 44 por padrão)
  int _semanaSelecionada = 44;
  final List<int> _semanasDisponiveis = [43, 44, 45, 46, 47];

  // Estado do Dia Selecionado (0 = Domingo, 1 = Segunda, 2 = Terça, etc.)
  int _diaSelecionadoIndex = 2; // Terça-feira selecionada por padrão

  final List<String> _diasLetras = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  final List<String> _diasNomes = [
    'Domingo',
    'Segunda-Feira',
    'Terça-Feira',
    'Quarta-Feira',
    'Quinta-Feira',
    'Sexta-Feira',
    'Sábado',
  ];

  // Simulação de dados de consumo em litros para a semana selecionada (7 dias)
  final List<double> _consumoSemanal = [520, 480, 347, 430, 390, 430, 520];

  @override
  Widget build(BuildContext context) {
    // Cálculo da média de consumo diário da semana
    final double mediaConsumo =
        _consumoSemanal.reduce((a, b) => a + b) / _consumoSemanal.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Inserindo logo e nome
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo_App_NC.png',
                    height: 70,
                    fit: BoxFit.contain,
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
              const SizedBox(height: 24),

              // Nome Histórico de Consumo
              const Text(
                'Histórico de Consumo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 12),

              // Card com Informações da Caixa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E2F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caixa: ${widget.nomeCaixa}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacidade: ${widget.capacidadeTotal.toInt()} L',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Seletor Horizontal de Semanas (S43, S44...)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _semanasDisponiveis.map((semana) {
                  final isSelected = semana == _semanaSelecionada;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _semanaSelecionada = semana;
                      });
                    },
                    child: Container(
                      width: 54,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D47A1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0D47A1),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'S$semana',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Texto com intervalo da Semana Selecionada
              Center(
                child: Text(
                  '25 de outubro - 31 de outubro (Semana $_semanaSelecionada)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Card do Gráfico de Média de Consumo Diário
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E2F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mediaConsumo.round()} Litros',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'Média de Consumo Diário',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gráfico de Barras Customizado
                    SizedBox(
                      height: 150,
                      child: Stack(
                        children: [
                          // Linhas de Guia e Legendas Laterais (500L, Média, 250L)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLinhaGuia('500L', Colors.grey.shade400),
                              _buildLinhaGuia(
                                'Média',
                                Colors.grey.shade500,
                                isDotted: true,
                              ),
                              _buildLinhaGuia('250L', Colors.grey.shade400),
                              const SizedBox(
                                height: 20,
                              ), // Compensação para o alinhamento das letras (D, S, T...)
                            ],
                          ),

                          // Desenho das Barras dos Dias da Semana (Com margem para não encostar na legenda)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 45.0,
                              ), // Garante o recuo exato para a legenda lateral
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(7, (index) {
                                  final double valor = _consumoSemanal[index];
                                  final double alturaProporcional =
                                      (valor / 600) * 110;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: alturaProporcional,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D47A1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _diasLetras[index],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botões Seletores de Dias da Semana (D, S, T, Q, Q, S, S)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isSelected = index == _diaSelecionadoIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _diaSelecionadoIndex = index;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D47A1)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D47A1),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _diasLetras[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Data por Extenso do Dia Selecionado
              Center(
                child: Text(
                  '${_diasNomes[_diaSelecionadoIndex]} - 27 de Outubro de 2026',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card Inferior de Consumo do Dia Selecionado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E2F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_consumoSemanal[_diaSelecionadoIndex].toInt()} Litros',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Consumidos nesta data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para desenhar as linhas tracejadas/guias do gráfico
  Widget _buildLinhaGuia(String texto, Color cor, {bool isDotted = false}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDotted ? Colors.transparent : cor,
            child: isDotted
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: List.generate(
                          (constraints.maxWidth / 6).floor(),
                          (index) => Container(
                            width: 3,
                            height: 1,
                            color: cor,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          ),
                        ),
                      );
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ),
      ],
    );
  }
}
