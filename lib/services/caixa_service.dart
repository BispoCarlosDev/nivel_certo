import 'package:nivel_certo/models/caixa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeituraAtual {
  final double volumeLitros;
  final DateTime dataHora;

  const LeituraAtual({required this.volumeLitros, required this.dataHora});
}

class ConsumoDia {
  final DateTime data;
  final double litros;
  final int leituras;

  const ConsumoDia({
    required this.data,
    required this.litros,
    required this.leituras,
  });
}

class DispositivoVinculado {
  final String identificador;
  final DateTime? ultimaComunicacao;

  const DispositivoVinculado({
    required this.identificador,
    required this.ultimaComunicacao,
  });
}

class CaixaService {
  CaixaService._();
  static final CaixaService instance = CaixaService._();

  SupabaseClient get _db => Supabase.instance.client;

  static String _data(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$mes-$dia';
  }

  Future<List<ModeloCaixa>> listarModelos() async {
    final dados = await _db
        .from('modelo_caixa')
        .select()
        .order('fabricante')
        .order('capacidade_litros');
    return dados.map((m) => ModeloCaixa.fromMap(m)).toList();
  }

  Future<List<Caixa>> listarCaixas() async {
    final dados = await _db
        .from('caixa_dagua')
        .select()
        .isFilter('excluida_em', null)
        .order('id');
    return dados.map((m) => Caixa.fromMap(m)).toList();
  }

  // Cria a caixa e devolve o id dela
  Future<int> criarCaixa(Map<String, dynamic> dados) async {
    final criada =
        await _db.from('caixa_dagua').insert(dados).select('id').single();
    return (criada['id'] as num).toInt();
  }

  // Conecta o dispositivo (código + chave da etiqueta) a uma caixa
  Future<void> vincularDispositivo(
    String identificador,
    String chave,
    int idCai,
  ) async {
    await _db.rpc('vincular_dispositivo', params: {
      'p_identificador': identificador,
      'p_chave': chave,
      'p_id_cai': idCai,
    });
  }

  // Dispositivo conectado a uma caixa (null se não houver)
  Future<DispositivoVinculado?> dispositivoDaCaixa(int idCai) async {
    final dados = await _db
        .from('dispositivo_medicao')
        .select('identificador, ultima_comunicacao')
        .eq('id_cai', idCai)
        .limit(1);
    if (dados.isEmpty) return null;
    final ultima = dados.first['ultima_comunicacao'] as String?;
    return DispositivoVinculado(
      identificador: dados.first['identificador'] as String,
      ultimaComunicacao:
          ultima == null ? null : DateTime.parse(ultima).toLocal(),
    );
  }

  Future<void> atualizarCaixa(int id, Map<String, dynamic> dados) async {
    await _db.from('caixa_dagua').update(dados).eq('id', id);
  }

  // A caixa não é apagada: guarda a data da exclusão e preserva o histórico
  Future<void> excluirCaixa(int id) async {
    await _db
        .from('caixa_dagua')
        .update({'excluida_em': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  // Recalcula o volume das leituras antigas depois de mudar as medidas
  Future<void> recalcularVolumes(int id) async {
    await _db.rpc('recalcular_volumes', params: {'p_id_cai': id});
  }

  Future<LeituraAtual?> ultimaLeitura(int idCai) async {
    final dados = await _db
        .from('leitura')
        .select('volume_litros, data_hora')
        .eq('id_cai', idCai)
        .not('volume_litros', 'is', null)
        .order('data_hora', ascending: false)
        .limit(1);
    if (dados.isEmpty) return null;
    return LeituraAtual(
      volumeLitros: numeroDe(dados.first['volume_litros']),
      dataHora: DateTime.parse(dados.first['data_hora'] as String).toLocal(),
    );
  }

  // Consumo de cada dia entre inicio e fim (inclusive), no fuso do usuário
  Future<List<ConsumoDia>> consumoDiario(
    int idCai,
    DateTime inicio,
    DateTime fim,
  ) async {
    final dados = await _db.rpc('consumo_diario', params: {
      'p_id_cai': idCai,
      'p_inicio': _data(inicio),
      'p_fim': _data(fim),
    }) as List;

    return dados.map((linha) {
      final mapa = Map<String, dynamic>.from(linha as Map);
      return ConsumoDia(
        data: DateTime.parse(mapa['data'] as String),
        litros: numeroDe(mapa['consumo_litros']),
        leituras: (mapa['qtd_leituras'] as num).toInt(),
      );
    }).toList();
  }

  // Litros que entraram na caixa em cada dia (sensor de vazão da entrada)
  Future<List<ConsumoDia>> abastecimentoDiario(
    int idCai,
    DateTime inicio,
    DateTime fim,
  ) async {
    final dados = await _db.rpc('abastecimento_diario', params: {
      'p_id_cai': idCai,
      'p_inicio': _data(inicio),
      'p_fim': _data(fim),
    }) as List;

    return dados.map((linha) {
      final mapa = Map<String, dynamic>.from(linha as Map);
      return ConsumoDia(
        data: DateTime.parse(mapa['data'] as String),
        litros: numeroDe(mapa['litros_entrada']),
        leituras: (mapa['qtd_leituras'] as num).toInt(),
      );
    }).toList();
  }
}
