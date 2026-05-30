import 'package:cloud_firestore/cloud_firestore.dart';

class AnaliseSalva {
  const AnaliseSalva({
    required this.id,
    required this.nome,
    required this.indicadorNome,
    required this.indicadorCodigo,
    required this.dataInicial,
    required this.dataFinal,
    required this.ultimoValor,
    required this.minimo,
    required this.maximo,
    required this.media,
    required this.variacaoPercentual,
    required this.desvioPadrao,
    required this.quantidade,
    required this.valores,
    required this.conclusao,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String indicadorNome;
  final int indicadorCodigo;
  final String dataInicial;
  final String dataFinal;
  final double ultimoValor;
  final double minimo;
  final double maximo;
  final double media;
  final double variacaoPercentual;
  final double desvioPadrao;
  final int quantidade;
  final List<Map<String, dynamic>> valores;
  final String conclusao;
  final DateTime? criadoEm;

  factory AnaliseSalva.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final estatisticas =
        (data['estatisticas'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final criadoEm = data['criadoEm'];
    final valoresRaw = data['valores'];

    return AnaliseSalva(
      id: doc.id,
      nome: (data['nome'] ?? '').toString(),
      indicadorNome: (data['indicadorNome'] ?? '').toString(),
      indicadorCodigo: _readInt(data['indicadorCodigo']),
      dataInicial: (data['dataInicial'] ?? '').toString(),
      dataFinal: (data['dataFinal'] ?? '').toString(),
      ultimoValor: _readDouble(estatisticas['ultimoValor']),
      minimo: _readDouble(estatisticas['minimo']),
      maximo: _readDouble(estatisticas['maximo']),
      media: _readDouble(estatisticas['media']),
      variacaoPercentual: _readDouble(estatisticas['variacaoPercentual']),
      desvioPadrao: _readDouble(estatisticas['desvioPadrao']),
      quantidade: _readInt(estatisticas['quantidade']),
      valores: valoresRaw is List
          ? valoresRaw
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList()
          : [],
      conclusao: (data['conclusao'] ?? '').toString(),
      criadoEm: criadoEm is Timestamp ? criadoEm.toDate() : null,
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
