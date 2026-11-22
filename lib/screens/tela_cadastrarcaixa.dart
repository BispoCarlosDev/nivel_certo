import 'package:flutter/material.dart';
import 'package:nivel_certo/models/caixa.dart';
import 'package:nivel_certo/services/auth_service.dart';
import 'package:nivel_certo/services/caixa_service.dart';
import 'package:nivel_certo/services/dispositivo_wifi_service.dart';

class CadastroCaixaScreen extends StatefulWidget {
  // Quando recebe uma caixa, a tela funciona como edição
  final Caixa? caixa;

  const CadastroCaixaScreen({super.key, this.caixa});

  @override
  State<CadastroCaixaScreen> createState() => _CadastroCaixaScreenState();
}

class _CadastroCaixaScreenState extends State<CadastroCaixaScreen> {
  static const String _generica = 'Genérica';

  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _tamanhoController = TextEditingController();
  final _modeloController = TextEditingController();
  final _alturaController = TextEditingController();
  final _alturaTampaController = TextEditingController();
  final _diametroTopoController = TextEditingController();
  final _diametroBaseController = TextEditingController();

  List<ModeloCaixa> _modelos = [];
  ModeloCaixa? _modeloSelecionado;
  bool _carregandoModelos = true;
  bool _salvando = false;
  String? _erroModelos;
  String? _erro;

  // Dispositivo digitado no app (será conectado ao confirmar) e dispositivo já conectado
  _Pareamento? _pendente;
  DispositivoVinculado? _vinculado;

  bool get _editando => widget.caixa != null;
  bool get _ehGenerica => _marcaController.text == _generica;

  List<TextEditingController> get _controllersMedidas => [
        _alturaController,
        _alturaTampaController,
        _diametroTopoController,
        _diametroBaseController,
      ];

  @override
  void initState() {
    super.initState();
    final caixa = widget.caixa;
    if (caixa != null) {
      _nomeController.text = caixa.nome;
      _marcaController.text = caixa.marca;
      _tamanhoController.text = caixa.capacidadeTexto;
      _modeloController.text = caixa.formatoTexto;
      if (caixa.marca == _generica) {
        _alturaController.text = formatarLitros(caixa.alturaCm);
        _alturaTampaController.text = formatarLitros(caixa.alturaSensorCm);
        _diametroTopoController.text = formatarLitros(caixa.diametroTopoCm);
        _diametroBaseController.text = formatarLitros(caixa.diametroBaseCm);
      }
    }
    _carregarModelos();
    _carregarVinculo();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _tamanhoController.dispose();
    _modeloController.dispose();
    for (final c in _controllersMedidas) {
      c.dispose();
    }
    super.dispose();
  }

  // Na edição, mostra qual dispositivo já está conectado à caixa
  Future<void> _carregarVinculo() async {
    final caixa = widget.caixa;
    if (caixa == null) return;
    try {
      final vinculado = await CaixaService.instance.dispositivoDaCaixa(caixa.id);
      if (!mounted) return;
      setState(() => _vinculado = vinculado);
    } catch (_) {
      // Sem a informação, o cartão apenas não mostra o dispositivo
    }
  }

  String _ha(DateTime data) {
    final d = DateTime.now().difference(data);
    if (d.inMinutes < 1) return 'há menos de 1 min';
    if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
    if (d.inHours < 24) return 'há ${d.inHours} h';
    return 'há ${d.inDays} d';
  }

  String _textoDispositivo() {
    final pendente = _pendente;
    if (pendente != null) {
      return 'Dispositivo ${pendente.codigo} será conectado ao confirmar.'
          '${pendente.ssid.isEmpty ? '' : '\nWi-Fi: ${pendente.ssid}'}';
    }
    final vinculado = _vinculado;
    if (vinculado != null) {
      final quando = vinculado.ultimaComunicacao;
      return 'Conectado: ${vinculado.identificador}\n'
          '${quando == null ? 'Ainda sem comunicação.' : 'Última comunicação ${_ha(quando)}.'}';
    }
    return 'Nenhum dispositivo conectado.';
  }

  String _mensagemVinculo(Object erro) {
    final texto = erro.toString();
    if (texto.contains('invalidos')) return 'código ou chave incorretos.';
    return AuthService.mensagemDe(erro);
  }

  // Pede o código e a chave da etiqueta do dispositivo e, se quiser, o Wi-Fi da casa
  Future<void> _conectarDispositivo() async {
    final codigoController = TextEditingController(
      text: _pendente?.codigo ?? _vinculado?.identificador ?? '',
    );
    final chaveController = TextEditingController(text: _pendente?.chave ?? '');
    final ssidController = TextEditingController(text: _pendente?.ssid ?? '');
    final senhaController = TextEditingController(text: _pendente?.senha ?? '');
    var ocultarSenha = true;
    String? erroDialogo;

    final resultado = await showDialog<_Pareamento>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogo) => AlertDialog(
          title: const Text('Conectar dispositivo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Digite o código e a chave que estão na etiqueta do dispositivo.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codigoController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _decoracao('Código do dispositivo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: chaveController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _decoracao('Chave do dispositivo'),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Wi-Fi da sua casa (opcional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preencha para configurar a internet do dispositivo. Use uma '
                  'rede de 2,4 GHz e mantenha o celular perto dele.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ssidController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _decoracao('Nome da rede Wi-Fi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senhaController,
                  obscureText: ocultarSenha,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Senha do Wi-Fi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        ocultarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogo(() => ocultarSenha = !ocultarSenha),
                    ),
                  ),
                ),
                if (erroDialogo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    erroDialogo!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final codigo = codigoController.text.trim().toUpperCase();
                final chave = chaveController.text.trim();
                final ssid = ssidController.text.trim();
                final senha = senhaController.text;
                String? erro;
                if (codigo.isEmpty || chave.isEmpty) {
                  erro = 'Preencha o código e a chave.';
                } else if (ssid.isEmpty && senha.isNotEmpty) {
                  erro = 'Informe o nome da rede Wi-Fi.';
                } else if (ssid.isNotEmpty &&
                    senha.isNotEmpty &&
                    (senha.length < 8 || senha.length > 63)) {
                  erro = 'A senha do Wi-Fi deve ter de 8 a 63 caracteres.';
                }
                if (erro != null) {
                  setDialogo(() => erroDialogo = erro);
                  return;
                }
                Navigator.pop(context, _Pareamento(codigo, chave, ssid, senha));
              },
              child: const Text('Conectar'),
            ),
          ],
        ),
      ),
    );

    if (resultado != null && mounted) {
      setState(() => _pendente = resultado);
    }
  }

  Future<void> _carregarModelos() async {
    setState(() {
      _carregandoModelos = true;
      _erroModelos = null;
    });
    try {
      final modelos = await CaixaService.instance.listarModelos();
      if (!mounted) return;
      setState(() {
        _modelos = modelos;
        _carregandoModelos = false;
        final idMod = widget.caixa?.idMod;
        if (idMod != null) {
          for (final m in modelos) {
            if (m.id == idMod) _modeloSelecionado = m;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoModelos = false;
        _erroModelos = AuthService.mensagemDe(e);
      });
    }
  }

  List<String> get _marcas => [
        ..._modelos.map((m) => m.fabricante).toSet(),
        _generica,
      ];

  List<ModeloCaixa> _modelosDa(String marca, int capacidade) => _modelos
      .where((m) => m.fabricante == marca && m.capacidadeLitros == capacidade)
      .toList();

  int? get _capacidadeEscolhida => int.tryParse(_tamanhoController.text);

  Future<String?> _escolher(String titulo, List<String> opcoes, String atual) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final opcao in opcoes)
                      ListTile(
                        title: Text(opcao),
                        trailing: opcao == atual
                            ? const Icon(Icons.check, color: Color(0xFF0D47A1))
                            : null,
                        onTap: () => Navigator.pop(context, opcao),
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

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _selecionarMarca() async {
    if (_carregandoModelos) return;
    final marca = await _escolher('Marca', _marcas, _marcaController.text);
    if (marca == null || marca == _marcaController.text) return;
    setState(() {
      _marcaController.text = marca;
      _tamanhoController.clear();
      _modeloController.text = marca == _generica ? 'Redonda' : '';
      _modeloSelecionado = null;
      for (final c in _controllersMedidas) {
        c.clear();
      }
    });
  }

  Future<void> _selecionarTamanho() async {
    final marca = _marcaController.text;
    if (marca.isEmpty) {
      _aviso('Escolha a marca primeiro.');
      return;
    }
    final capacidades = _modelos
        .where((m) => m.fabricante == marca)
        .map((m) => m.capacidadeLitros)
        .toSet()
        .toList()
      ..sort();
    final atual =
        _tamanhoController.text.isEmpty ? '' : '${_tamanhoController.text} L';
    final escolhido = await _escolher(
      'Tamanho (Litros)',
      capacidades.map((c) => '$c L').toList(),
      atual,
    );
    if (escolhido == null) return;

    final capacidade = int.parse(escolhido.replaceAll(' L', ''));
    final opcoes = _modelosDa(marca, capacidade);
    setState(() {
      _tamanhoController.text = '$capacidade';
      if (opcoes.length == 1) {
        _modeloSelecionado = opcoes.first;
        _modeloController.text = opcoes.first.formatoTexto;
      } else {
        _modeloSelecionado = null;
        _modeloController.clear();
      }
    });
  }

  Future<void> _selecionarModelo() async {
    if (_ehGenerica) {
      final escolhido = await _escolher('Modelo', ['Redonda'], 'Redonda');
      if (escolhido != null) _modeloController.text = escolhido;
      return;
    }

    final capacidade = _capacidadeEscolhida;
    if (_marcaController.text.isEmpty || capacidade == null) {
      _aviso('Escolha a marca e o tamanho primeiro.');
      return;
    }
    final opcoes = _modelosDa(_marcaController.text, capacidade);
    final escolhido = await _escolher(
      'Modelo',
      opcoes.map((m) => m.formatoTexto).toList(),
      _modeloController.text,
    );
    if (escolhido == null) return;
    setState(() {
      _modeloSelecionado =
          opcoes.firstWhere((m) => m.formatoTexto == escolhido);
      _modeloController.text = escolhido;
    });
  }

  double? _ler(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  bool _mudouMedidas(Caixa caixa, Map<String, dynamic> dados) {
    bool diferente(double a, dynamic b) => (a - numeroDe(b)).abs() > 0.001;
    return diferente(caixa.capacidadeLitros, dados['capacidade_litros']) ||
        diferente(caixa.alturaCm, dados['altura_cm']) ||
        diferente(caixa.alturaSensorCm, dados['altura_sensor_cm']) ||
        diferente(caixa.diametroTopoCm, dados['diametro_topo_cm']) ||
        diferente(caixa.diametroBaseCm, dados['diametro_base_cm']);
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome da caixa.');
      return;
    }
    if (_marcaController.text.isEmpty) {
      setState(() => _erro = 'Escolha a marca da caixa.');
      return;
    }

    final Map<String, dynamic> medidas;
    if (_ehGenerica) {
      final capacidade = _ler(_tamanhoController);
      final altura = _ler(_alturaController);
      final alturaTampa = _ler(_alturaTampaController);
      final diametroTopo = _ler(_diametroTopoController);
      final diametroBase = _ler(_diametroBaseController);
      final valores = [
        capacidade,
        altura,
        alturaTampa,
        diametroTopo,
        diametroBase,
      ];
      if (valores.any((v) => v == null || v <= 0)) {
        setState(() => _erro =
            'Preencha o tamanho e todas as medidas com valores maiores que zero.');
        return;
      }
      if (alturaTampa! < altura!) {
        setState(() => _erro =
            'A altura com tampa não pode ser menor que a altura sem tampa.');
        return;
      }
      medidas = {
        'id_mod': null,
        'marca': _generica,
        'formato': 'redonda',
        'capacidade_litros': capacidade,
        'altura_cm': altura,
        'altura_sensor_cm': alturaTampa,
        'diametro_topo_cm': diametroTopo,
        'diametro_base_cm': diametroBase,
      };
    } else {
      final modelo = _modeloSelecionado;
      final original = widget.caixa;
      if (modelo != null) {
        // Mantém a altura do sensor já ajustada quando o modelo não mudou
        final alturaSensor = (original != null && original.idMod == modelo.id)
            ? original.alturaSensorCm
            : modelo.alturaComTampaCm;
        medidas = {
          'id_mod': modelo.id,
          'marca': modelo.fabricante,
          'formato': modelo.formato,
          'capacidade_litros': modelo.capacidadeLitros,
          'altura_cm': modelo.alturaCm,
          'altura_sensor_cm': alturaSensor,
          'diametro_topo_cm': modelo.diametroTopoCm,
          'diametro_base_cm': modelo.diametroBaseCm,
        };
      } else if (original != null &&
          _marcaController.text == original.marca &&
          _tamanhoController.text == original.capacidadeTexto) {
        medidas = {
          'id_mod': original.idMod,
          'marca': original.marca,
          'formato': original.formato,
          'capacidade_litros': original.capacidadeLitros,
          'altura_cm': original.alturaCm,
          'altura_sensor_cm': original.alturaSensorCm,
          'diametro_topo_cm': original.diametroTopoCm,
          'diametro_base_cm': original.diametroBaseCm,
        };
      } else {
        setState(() => _erro = 'Escolha o tamanho e o modelo da caixa.');
        return;
      }
    }

    final dados = {'nome': nome, ...medidas};
    final caixa = widget.caixa;
    final messenger = ScaffoldMessenger.of(context);
    var recalculou = true;
    var idCaixa = caixa?.id ?? 0;

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      if (caixa == null) {
        idCaixa = await CaixaService.instance.criarCaixa(dados);
      } else {
        await CaixaService.instance.atualizarCaixa(caixa.id, dados);
        if (_mudouMedidas(caixa, dados)) {
          try {
            await CaixaService.instance.recalcularVolumes(caixa.id);
          } catch (_) {
            recalculou = false;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = AuthService.mensagemDe(e);
      });
      return;
    }
    if (!mounted) return;

    // Conecta o dispositivo digitado, agora que a caixa existe
    String? avisoVinculo;
    final pendente = _pendente;
    if (pendente != null) {
      try {
        await CaixaService.instance
            .vincularDispositivo(pendente.codigo, pendente.chave, idCaixa);
      } catch (e) {
        avisoVinculo = _mensagemVinculo(e);
      }
      if (!mounted) return;
    }

    // Envia o Wi-Fi ao dispositivo por Bluetooth (só se o vínculo deu certo)
    String? avisoWifi;
    var wifiEnviado = false;
    if (pendente != null && pendente.ssid.isNotEmpty && avisoVinculo == null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Configurando o Wi-Fi do dispositivo...\n'
                  'Mantenha o celular perto dele.',
                ),
              ),
            ],
          ),
        ),
      );
      try {
        await DispositivoWifiService.instance.configurarWifi(
          codigo: pendente.codigo,
          chave: pendente.chave,
          ssid: pendente.ssid,
          senha: pendente.senha,
        );
        wifiEnviado = true;
      } catch (e) {
        avisoWifi = e is ConfigWifiException
            ? e.mensagem
            : 'Não foi possível configurar o Wi-Fi do dispositivo.';
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // fecha o aviso de progresso
    }

    // Volta para Minhas Caixas
    Navigator.pop(context, true);
    if (avisoWifi != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Caixa salva, mas o Wi-Fi não foi configurado: $avisoWifi '
            'Edite a caixa para tentar de novo.',
          ),
        ),
      );
    } else if (wifiEnviado) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Wi-Fi enviado ao dispositivo. Em até 2 minutos ele começa a enviar leituras.',
          ),
        ),
      );
    } else if (avisoVinculo != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Caixa salva, mas o dispositivo não foi conectado: $avisoVinculo '
            'Edite a caixa para tentar de novo.',
          ),
        ),
      );
    } else if (!recalculou) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Caixa atualizada, mas não foi possível recalcular as leituras antigas.',
          ),
        ),
      );
    }
  }

  InputDecoration _decoracao(String label, {bool seletor = false}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: seletor ? const Icon(Icons.keyboard_arrow_down) : null,
    );
  }

  Widget _campoNumero(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoracao(label),
    );
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
                _editando ? 'Editar Caixa D\'Água' : 'Cadastrar Caixa D\'Água',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 24),

              // Cartão para conectar o dispositivo (código + chave da etiqueta)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          onPressed: _salvando ? null : _conectarDispositivo,
                          icon: const Icon(
                            Icons.sync,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _pendente != null || _vinculado != null
                                ? 'Alterar'
                                : 'Conectar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _textoDispositivo(),
                      style: TextStyle(
                        fontSize: 13,
                        color: _pendente != null
                            ? Colors.green.shade800
                            : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_carregandoModelos) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              if (_erroModelos != null) ...[
                Text(
                  'Não foi possível carregar o catálogo de marcas. $_erroModelos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                TextButton(
                  onPressed: _carregarModelos,
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(height: 8),
              ],

              // Inserindo o campo Nome da Caixa
              TextField(
                controller: _nomeController,
                decoration: _decoracao('Nome da Caixa'),
              ),
              const SizedBox(height: 16),

              // Inserindo o campo marca da Caixa
              TextField(
                controller: _marcaController,
                readOnly: true,
                onTap: _selecionarMarca,
                decoration: _decoracao('Marca Caixa D\'Água', seletor: true),
              ),
              const SizedBox(height: 16),

              // Inserindo o campo de tamanho da caixa
              if (_ehGenerica)
                _campoNumero('Tamanho (Litros)', _tamanhoController)
              else
                TextField(
                  controller: _tamanhoController,
                  readOnly: true,
                  onTap: _selecionarTamanho,
                  decoration: _decoracao('Tamanho (Litros)', seletor: true),
                ),
              const SizedBox(height: 16),

              // Inserindo o modelo da caixa
              TextField(
                controller: _modeloController,
                readOnly: true,
                onTap: _selecionarModelo,
                decoration: _decoracao('Modelo', seletor: true),
              ),
              const SizedBox(height: 16),

              // Medidas digitadas pelo usuário quando a marca é Genérica
              if (_ehGenerica) ...[
                const Text(
                  'Informe as medidas da caixa, em centímetros. A altura com '
                  'tampa é a distância da base até o topo da tampa, onde fica '
                  'o sensor.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                _campoNumero('Altura sem tampa (cm)', _alturaController),
                const SizedBox(height: 16),
                _campoNumero('Altura com tampa (cm)', _alturaTampaController),
                const SizedBox(height: 16),
                _campoNumero('Diâmetro do topo (cm)', _diametroTopoController),
                const SizedBox(height: 16),
                _campoNumero('Diâmetro da base (cm)', _diametroBaseController),
                const SizedBox(height: 16),
              ],

              if (_erro != null) ...[
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),

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
                  onPressed: _salvando || _carregandoModelos ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
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

// Código e chave digitados pelo usuário para conectar o dispositivo
class _Pareamento {
  final String codigo;
  final String chave;
  final String ssid;   // vazio = não configurar o Wi-Fi
  final String senha;

  const _Pareamento(this.codigo, this.chave, this.ssid, this.senha);
}
