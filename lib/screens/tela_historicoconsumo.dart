import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nivel_certo/models/caixa.dart';
import 'package:nivel_certo/services/caixa_service.dart';

class HistoricoConsumoScreen extends StatefulWidget {
  final Caixa caixa;

  // false = Histórico de Consumo | true = Histórico de Abastecimento
  final bool abastecimento;

  const HistoricoConsumoScreen({
    super.key,
    required this.caixa,
    this.abastecimento = false,
  });

  @override
  State<HistoricoConsumoScreen> createState() => _HistoricoConsumoScreenState();
}

class _HistoricoConsumoScreenState extends State<HistoricoConsumoScreen> {
  static const int _quantidadeSemanas = 5;
  static const double _alturaBarras = 110;
  static const double _larguraLegenda = 48;

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

  bool get _ab => widget.abastecimento;

  late final DateTime _hoje;
  late final DateTime _inicioSemanaAtual; // Domingo da semana de hoje
  late DateTime _ultimaSemanaExibida; // Domingo da semana mais à direita do seletor
  late DateTime _inicioSemanaSelecionada; // Domingo da semana selecionada
  late int _diaSelecionadoIndex; // 0 = Domingo, 1 = Segunda, ..., 6 = Sábado

  // Consumo dos 7 dias da semana selecionada (domingo a sábado)
  List<double> _litros = List.filled(7, 0);
  List<bool> _temDados = List.filled(7, false);
  bool _carregando = true;
  bool _erro = false;
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _hoje = DateTime(agora.year, agora.month, agora.day);
    _inicioSemanaAtual = _domingoDa(_hoje);
    _ultimaSemanaExibida = _inicioSemanaAtual;
    _inicioSemanaSelecionada = _inicioSemanaAtual;
    _diaSelecionadoIndex = _hoje.weekday % 7;
    _carregarSemana();
  }

  DateTime _domingoDa(DateTime data) =>
      DateTime(data.year, data.month, data.day - (data.weekday % 7));

  DateTime _somarDias(DateTime data, int dias) =>
      DateTime(data.year, data.month, data.day + dias);

  String _chave(DateTime data) => '${data.year}-${data.month}-${data.day}';

  // Dias que ainda não aconteceram não podem ser selecionados
  bool _ehFuturo(int indice) =>
      _somarDias(_inicioSemanaSelecionada, indice).isAfter(_hoje);

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

  // Busca no banco o consumo de cada dia da semana selecionada
  Future<void> _carregarSemana() async {
    final requisicao = ++_requisicao;
    final inicio = _inicioSemanaSelecionada;
    try {
      final fim = _somarDias(inicio, 6);
      final consumo = _ab
          ? await CaixaService.instance.abastecimentoDiario(
              widget.caixa.id,
              inicio,
              fim,
            )
          : await CaixaService.instance.consumoDiario(
              widget.caixa.id,
              inicio,
              fim,
            );
      // Ignora respostas de semanas que já não estão selecionadas
      if (!mounted || requisicao != _requisicao) return;

      final porData = {for (final c in consumo) _chave(c.data): c};
      final litros = <double>[];
      final temDados = <bool>[];
      for (var i = 0; i < 7; i++) {
        final dia = porData[_chave(_somarDias(inicio, i))];
        litros.add(dia?.litros ?? 0);
        temDados.add((dia?.leituras ?? 0) > 0);
      }
      setState(() {
        _litros = litros;
        _temDados = temDados;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted || requisicao != _requisicao) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  void _recarregar() {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    _carregarSemana();
  }

  void _selecionarSemana(DateTime inicio) {
    setState(() {
      _inicioSemanaSelecionada = inicio;
      final data = _somarDias(inicio, _diaSelecionadoIndex);
      if (data.isAfter(_hoje)) _diaSelecionadoIndex = _hoje.weekday % 7;
      _carregando = true;
      _erro = false;
    });
    _carregarSemana();
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
      _carregando = true;
      _erro = false;

      // Se a semana escolhida é mais antiga que as exibidas, o seletor se desloca até ela
      final primeiraExibida =
          _somarDias(_ultimaSemanaExibida, -7 * (_quantidadeSemanas - 1));
      if (inicio.isBefore(primeiraExibida)) {
        final ultima = _somarDias(inicio, 7 * (_quantidadeSemanas - 1));
        _ultimaSemanaExibida =
            ultima.isAfter(_inicioSemanaAtual) ? _inicioSemanaAtual : ultima;
      }
    });
    _carregarSemana();
  }

  // Valor máximo do eixo do gráfico, arredondado para cima
  double _tetoDoGrafico(double maximo) {
    final passo = maximo <= 1000
        ? 100.0
        : maximo <= 5000
            ? 500.0
            : 1000.0;
    final teto = (maximo / passo).ceil() * passo;
    return teto < passo ? passo : teto;
  }

  // Linhas de referência do gráfico: topo, metade e média da semana
  List<Widget> _linhasGuia(double teto, double? media) {
    double posicao(double valor) =>
        _alturaBarras - (valor / teto) * _alturaBarras;

    final yMedia = media == null ? null : posicao(media);
    final yMeio = posicao(teto / 2);
    final linhas = <Widget>[];

    void adicionar(double y, String texto, Color cor, {bool pontilhada = false}) {
      linhas.add(
        Positioned(
          top: y - 7,
          left: 0,
          right: 0,
          child: _buildLinhaGuia(texto, cor, isDotted: pontilhada),
        ),
      );
    }

    if (yMedia == null || yMedia > 14) {
      adicionar(0, '${formatarLitros(teto)}L', Colors.grey.shade400);
    }
    if (yMedia == null || (yMedia - yMeio).abs() > 14) {
      adicionar(yMeio, '${formatarLitros(teto / 2)}L', Colors.grey.shade400);
    }
    if (yMedia != null) {
      adicionar(yMedia, 'Média', Colors.grey.shade500, pontilhada: true);
    }
    return linhas;
  }

  @override
  Widget build(BuildContext context) {
    // Média de consumo diário, considerando só os dias que têm leituras
    final List<double> diasComDados = [
      for (var i = 0; i < 7; i++)
        if (_temDados[i] && !_ehFuturo(i)) _litros[i],
    ];
    final double? mediaConsumo = diasComDados.isEmpty
        ? null
        : diasComDados.reduce((a, b) => a + b) / diasComDados.length;
    final double totalSemana =
        diasComDados.isEmpty ? 0.0 : diasComDados.reduce((a, b) => a + b);

    final double teto = _tetoDoGrafico(
      diasComDados.isEmpty ? 0.0 : diasComDados.reduce(max),
    );

    final DateTime dataSelecionada =
        _somarDias(_inicioSemanaSelecionada, _diaSelecionadoIndex);
    final bool diaComDados = _temDados[_diaSelecionadoIndex];
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

              // Nome da tela (Consumo ou Abastecimento)
              Text(
                _ab ? 'Histórico de Abastecimento' : 'Histórico de Consumo',
                style: const TextStyle(
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
                      'Caixa: ${widget.caixa.nome}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacidade: ${widget.caixa.capacidadeTexto} L',
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

              // Texto com intervalo da Semana Selecionada e botão do calendário
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
              if (_carregando)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              const SizedBox(height: 16),

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
                      mediaConsumo == null
                          ? '-- Litros'
                          : _ab
                              ? '${totalSemana.round()} Litros'
                              : '${mediaConsumo.round()} Litros',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      _ab ? 'Recebidos na Semana' : 'Média de Consumo Diário',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gráfico de Barras Customizado
                    SizedBox(
                      height: 150,
                      child: Column(
                        children: [
                          SizedBox(
                            height: _alturaBarras,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Linhas de Guia e Legendas Laterais
                                ..._linhasGuia(teto, mediaConsumo),

                                // Desenho das Barras dos Dias da Semana (Com margem para não encostar na legenda)
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      right: _larguraLegenda + 5,
                                    ), // Garante o recuo exato para a legenda lateral
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: List.generate(7, (index) {
                                        final double valor =
                                            _ehFuturo(index) ? 0 : _litros[index];
                                        final double alturaProporcional =
                                            (valor / teto * _alturaBarras)
                                                .clamp(0.0, _alturaBarras);

                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 400),
                                          curve: Curves.easeOutCubic,
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
                                ),
                              ],
                            ),
                          ),

                          // Linha na base das colunas
                          Padding(
                            padding: const EdgeInsets.only(
                              right: _larguraLegenda + 5,
                            ),
                            child: Container(
                              height: 2,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Letras dos dias da semana
                          Padding(
                            padding: const EdgeInsets.only(
                              right: _larguraLegenda + 5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_erro) ...[
                const SizedBox(height: 8),
                Text(
                  _ab
                      ? 'Não foi possível carregar o abastecimento desta semana.'
                      : 'Não foi possível carregar o consumo desta semana.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                TextButton(
                  onPressed: _recarregar,
                  child: const Text(
                    'Tentar novamente',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Botões Seletores de Dias da Semana (D, S, T, Q, Q, S, S)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isSelected = index == _diaSelecionadoIndex;
                  final bool disponivel = !_ehFuturo(index);
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
                      diaComDados
                          ? '${_litros[_diaSelecionadoIndex].round()} Litros'
                          : 'Sem dados',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !diaComDados
                          ? 'Nenhuma leitura registrada nesta data'
                          : _ab
                              ? (_litros[_diaSelecionadoIndex] >= 1
                                  ? 'Recebidos nesta data'
                                  : 'Nenhuma água recebida nesta data')
                              : 'Consumidos nesta data',
                      style: const TextStyle(
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
    return SizedBox(
      height: 14,
      child: Row(
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
            width: _larguraLegenda - 8,
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
      ),
    );
  }
}
