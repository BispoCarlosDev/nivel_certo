import 'package:flutter/material.dart';
import 'package:nivel_certo/screens/tela_historicoconsumo.dart';

class NivelAguaScreen extends StatefulWidget {
  final String nomeCaixa;
  final double capacidadeTotal;

  const NivelAguaScreen({
    super.key,
    this.nomeCaixa = 'Nome da Caixa',
    this.capacidadeTotal = 1000.0,
  });

  @override
  State<NivelAguaScreen> createState() => _NivelAguaScreenState();
}

class _NivelAguaScreenState extends State<NivelAguaScreen> {
  // Simulação do volume atual recebido que vai ser recebido da ESP32
  double _litrosAtuais = 320.0;

  @override
  Widget build(BuildContext context) {
    // Cálculo do percentual limitado entre 0.0 e 1.0 (0% a 100%)
    final double porcentagem = (_litrosAtuais / widget.capacidadeTotal).clamp(0.0, 1.0);
    final int percentualInt = (porcentagem * 100).round();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Inserindo o Logo e o nome
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
              const SizedBox(height: 28),

              // Título da Tela Nível de Água
              const Text(
                'Nível de Água',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 14),

              // Informações da Caixa D'Água
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacidade: ${widget.capacidadeTotal.toInt()} L',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Seção com os dados de nível de água
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Representação Gráfica Dinâmica
                  Container(
                    width: 120,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0D47A1), width: 1.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Preenchimento de Água Animado
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            // Altura proporcional da água baseada nos 280px totais
                            height: 280 * porcentagem,
                            color: const Color(0xFF0288D1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),

                  // Informações Numéricas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Valor em Litros
                        Text(
                          '${_litrosAtuais.toInt()}',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D47A1),
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'Litros',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Percentual
                        Text(
                          '$percentualInt%',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'de ${widget.capacidadeTotal.toInt()} Litros\nTotais',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Botão Histórico de Consumo
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navegação para a tela de histórico, levando os dados da caixa
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoricoConsumoScreen(
                          nomeCaixa: widget.nomeCaixa,
                          capacidadeTotal: widget.capacidadeTotal,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Histórico de Consumo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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