double numeroDe(dynamic valor) =>
    valor is num ? valor.toDouble() : double.parse(valor.toString());

// Exibe 500.0 como "500" e 12.5 como "12,5"
String formatarLitros(double valor) => valor == valor.roundToDouble()
    ? valor.toInt().toString()
    : valor.toStringAsFixed(1).replaceAll('.', ',');

String _primeiraMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

// Caixa d'água cadastrada pelo usuário
class Caixa {
  final int id;
  final int? idMod;
  final String nome;
  final String marca;
  final String formato;
  final double capacidadeLitros;
  final double alturaCm;
  final double diametroTopoCm;
  final double diametroBaseCm;
  final double alturaSensorCm;

  const Caixa({
    required this.id,
    required this.idMod,
    required this.nome,
    required this.marca,
    required this.formato,
    required this.capacidadeLitros,
    required this.alturaCm,
    required this.diametroTopoCm,
    required this.diametroBaseCm,
    required this.alturaSensorCm,
  });

  factory Caixa.fromMap(Map<String, dynamic> mapa) => Caixa(
        id: (mapa['id'] as num).toInt(),
        idMod: (mapa['id_mod'] as num?)?.toInt(),
        nome: mapa['nome'] as String,
        marca: mapa['marca'] as String,
        formato: mapa['formato'] as String,
        capacidadeLitros: numeroDe(mapa['capacidade_litros']),
        alturaCm: numeroDe(mapa['altura_cm']),
        diametroTopoCm: numeroDe(mapa['diametro_topo_cm']),
        diametroBaseCm: numeroDe(mapa['diametro_base_cm']),
        alturaSensorCm: numeroDe(mapa['altura_sensor_cm']),
      );

  // Código exibido no card (ex.: 001)
  String get codigo => id.toString().padLeft(3, '0');

  String get capacidadeTexto => formatarLitros(capacidadeLitros);

  String get formatoTexto => _primeiraMaiuscula(formato);
}

// Modelo do catálogo dos fabricantes
class ModeloCaixa {
  final int id;
  final String fabricante;
  final String formato;
  final int capacidadeLitros;
  final double alturaCm;
  final double alturaComTampaCm;
  final double diametroTopoCm;
  final double diametroBaseCm;

  const ModeloCaixa({
    required this.id,
    required this.fabricante,
    required this.formato,
    required this.capacidadeLitros,
    required this.alturaCm,
    required this.alturaComTampaCm,
    required this.diametroTopoCm,
    required this.diametroBaseCm,
  });

  factory ModeloCaixa.fromMap(Map<String, dynamic> mapa) => ModeloCaixa(
        id: (mapa['id'] as num).toInt(),
        fabricante: mapa['fabricante'] as String,
        formato: mapa['formato'] as String,
        capacidadeLitros: (mapa['capacidade_litros'] as num).toInt(),
        alturaCm: numeroDe(mapa['altura_cm']),
        alturaComTampaCm: numeroDe(mapa['altura_com_tampa_cm']),
        diametroTopoCm: numeroDe(mapa['diametro_topo_cm']),
        diametroBaseCm: numeroDe(mapa['diametro_base_cm']),
      );

  String get formatoTexto => _primeiraMaiuscula(formato);
}
