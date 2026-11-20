import 'dart:math';
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
  static const int _quantidadeSemanas = 5;

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
  final List<String> _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  late final DateTime _hoje;
  late final DateTime _inicioSemanaAtual; // Domingo da semana de hoje
  late DateTime _ultimaSemanaExibida; // Domingo da semana mais à direita do seletor
  late DateTime _inicioSemanaSelecionada; // Domingo da semana selecionada
  late int _diaSelecionadoIndex; // 0 = Domingo, 1 = Segunda, ..., 6 = Sábado

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _hoje = DateTime(agora.year, agora.month, agora.day);
    _inicioSemanaAtual = _domingoDa(_hoje);
    _ultimaSemanaExibida = _inicioSemanaAtual;
    _inicioSemanaSelecionada = _inicioSemanaAtual;
    _diaSelecionadoIndex = _hoje.weekday % 7;
  }

  DateTime _domingoDa(DateTime data) =>
      DateTime(data.year, data.month, data.day - (data.weekday % 7));

  DateTime _somarDias(DateTime data, int dias) =>
      DateTime(data.year, data.month, data.day + dias);

  // A semana 1 do ano é a que contém o dia 1º de janeiro (semanas de domingo a sábado)
  int _numeroDaSemana(DateTime inicio) {
    final fim = _somarDias(inicio, 6);
    final primeiroDomingo = _domingoDa(DateTime(fim.year, 1, 1));
    final dias = DateTime.utc(inicio.year, inicio.month, inicio.day)
        .difference(
          DateTime.utc(
            primeiroDomingo.year,
            primeiroDomingo.month,
            primeiroDomingo.day,
          ),
        )
        .inDays;
    return dias ~/ 7 + 1;
  }

  String _maiuscula(String texto) => texto[0].toUpperCase() + texto.substring(1);

  String _intervaloDaSemana(DateTime inicio) {
    final fim = _somarDias(inicio, 6);
    return '${inicio.day} de ${_meses[inicio.month - 1]} - '
        '${fim.day} de ${_meses[fim.month - 1]} '
        '(Semana ${_numeroDaSemana(inicio)})';
  }

  // Consumo em litros dos 7 dias da semana (domingo a sábado).
  // Dias que ainda não aconteceram ficam sem valor (null).
  List<double?> _consumoDaSemana(DateTime inicio) {
    final semente =
        DateTime.utc(inicio.year, inicio.month, inicio.day).millisecondsSinceEpoch ~/
            86400000;
    final aleatorio = Random(semente);
    return List.generate(7, (i) {
      final valor = (280 + aleatorio.nextInt(300)).toDouble();
      return _somarDias(inicio, i).isAfter(_hoje) ? null : valor;
    });
  }

  void _selecionarSemana(DateTime inicio) {
    setState(() {
      _inicioSemanaSelecionada = inicio;
      final data = _somarDias(inicio, _diaSelecionadoIndex);
      if (data.isAfter(_hoje)) _diaSelecionadoIndex = _hoje.weekday % 7;
    });
  }

  // Abre o calendário para buscar qualquer data; seleciona a semana e o dia escolhidos
  Future<void> _abrirCalendario() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _somarDias(_inicioSemanaSelecionada, _diaSelecionadoIndex),
      firstDate: DateTime(2024, 1, 1),
      lastDate: _hoje,
      helpText: 'Selecione uma data',
    );
    if (data == null || !mounted) return;

    setState(() {
      final inicio = _domingoDa(data);
      _inicioSemanaSelecionada = inicio;
      _diaSelecionadoIndex = data.weekday % 7;

      // Se a semana escolhida é mais antiga que as exibidas, o seletor se desloca até ela
      final primeiraExibida =
          _somarDias(_ultimaSemanaExibida, -7 * (_quantidadeSemanas - 1));
      if (inicio.isBefore(primeiraExibida)) {
        final ultima = _somarDias(inicio, 7 * (_quantidadeSemanas - 1));
        _ultimaSemanaExibida =
            ultima.isAfter(_inicioSemanaAtual) ? _inicioSemanaAtual : ultima;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<double?> consumo = _consumoDaSemana(_inicioSemanaSelecionada);
    final List<double> diasComDados = consumo.whereType<double>().toList();

    // Cálculo da média de consumo diário da semana
    final double mediaConsumo = diasComDados.isEmpty
        ? 0
        : diasComDados.reduce((a, b) => a + b) / diasComDados.length;

    final DateTime dataSelecionada =
        _somarDias(_inicioSemanaSelecionada, _diaSelecionadoIndex);
    final List<DateTime> semanas = List.generate(
      _quantidadeSemanas,
      (i) => _somarDias(
        _ultimaSemanaExibida,
        -7 * (_quantidadeSemanas - 1 - i),
      ),
    );

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
                children: semanas.map((inicioSemana) {
                  final isSelected = inicioSemana == _inicioSemanaSelecionada;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _selecionarSemana(inicioSemana),
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
                        'S${_numeroDaSemana(inicioSemana)}',
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _intervaloDaSemana(_inicioSemanaSelecionada),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Buscar no calendário',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF0D47A1),
                    ),
                    onPressed: _abrirCalendario,
                  ),
                ],
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
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: List.generate(7, (index) {
                                        final double? valor = consumo[index];
                                        final double alturaProporcional =
                                            valor == null ? 0 : (valor / 600) * 110;

                                        return Container(
                                          width: 16,
                                          height: alturaProporcional,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0D47A1),
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),

                                  // Linha na base das colunas
                                  Container(
                                    height: 2,
                                    color: const Color(0xFF0D47A1),
                                  ),
                                  const SizedBox(height: 6),

                                  // Letras dos dias da semana
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: List.generate(7, (index) {
                                      return SizedBox(
                                        width: 16,
                                        child: Text(
                                          _diasLetras[index],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
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
                  final bool disponivel = consumo[index] != null;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: disponivel
                        ? () {
                            setState(() {
                              _diaSelecionadoIndex = index;
                            });
                          }
                        : null,
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
                          color: disponivel
                              ? const Color(0xFF0D47A1)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _diasLetras[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: !disponivel
                              ? Colors.grey.shade400
                              : isSelected
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
                  '${_diasNomes[_diaSelecionadoIndex]} - ${dataSelecionada.day} de '
                  '${_maiuscula(_meses[dataSelecionada.month - 1])} de ${dataSelecionada.year}',
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
                      '${consumo[_diaSelecionadoIndex]!.toInt()} Litros',
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
