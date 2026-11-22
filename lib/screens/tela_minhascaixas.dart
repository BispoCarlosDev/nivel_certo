import 'package:flutter/material.dart';
import 'package:nivel_certo/models/caixa.dart';
import 'package:nivel_certo/screens/tela_cadastrarcaixa.dart';
import 'package:nivel_certo/screens/tela_login.dart';
import 'package:nivel_certo/screens/tela_niveldeagua.dart';
import 'package:nivel_certo/services/auth_service.dart';
import 'package:nivel_certo/services/caixa_service.dart';

class MinhasCaixasScreen extends StatefulWidget {
  const MinhasCaixasScreen({super.key});

  @override
  State<MinhasCaixasScreen> createState() => _MinhasCaixasScreenState();
}

class _MinhasCaixasScreenState extends State<MinhasCaixasScreen> {
  List<Caixa> _caixas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool mostrarCarregando = true}) async {
    if (mostrarCarregando) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final caixas = await CaixaService.instance.listarCaixas();
      if (!mounted) return;
      setState(() {
        _caixas = caixas;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = AuthService.mensagemDe(e);
      });
    }
  }

  Future<void> _sair() async {
    await AuthService.instance.sair();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (rota) => false,
    );
  }

  // Abre a tela de cadastro e recarrega a lista se algo foi salvo
  Future<void> _abrirCadastro({Caixa? caixa}) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CadastroCaixaScreen(caixa: caixa)),
    );
    if (salvou == true) _carregar(mostrarCarregando: false);
  }

  // Pede confirmação antes de excluir a caixa
  Future<void> _confirmarExclusao(Caixa caixa) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir caixa'),
        content: Text(
          'Deseja realmente excluir a caixa "${caixa.nome}"? '
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
    if (confirmou != true) return;

    try {
      await CaixaService.instance.excluirCaixa(caixa.id);
      if (!mounted) return;
      setState(() => _caixas.removeWhere((c) => c.id == caixa.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caixa excluída.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.mensagemDe(e))),
      );
    }
  }

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
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout, color: Color(0xFF0D47A1)),
                    onPressed: _sair,
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

              // Seleção de Opções: carregando, erro, sem caixas ou com caixas
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _erro != null
                        ? _construirErro()
                        : RefreshIndicator(
                            onRefresh: () => _carregar(mostrarCarregando: false),
                            child: _caixas.isNotEmpty
                                ? _construirListaCaixas()
                                : ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [_construirEstadoVazio()],
                                  ),
                          ),
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
        onPressed: () => _abrirCadastro(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Widget para quando não foi possível carregar as caixas
  Widget _construirErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _erro!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _carregar,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
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
                // Ação ao clicar no card da caixa: abre a tela de nível de água
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NivelAguaScreen(caixa: caixa),
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
                            'Código: ${caixa.codigo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nome: ${caixa.nome}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Marca: ${caixa.marca}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modelo: ${caixa.formatoTexto}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tamanho: ${caixa.capacidadeTexto}L',
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
                          _abrirCadastro(caixa: caixa);
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
