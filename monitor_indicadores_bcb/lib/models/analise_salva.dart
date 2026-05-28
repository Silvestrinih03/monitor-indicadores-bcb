import 'package:cloud_firestore/cloud_firestore.dart';

class AnaliseSalva {
  const AnaliseSalva({
    required this.id,
    required this.nome,
    required this.observacao,
    required this.indicadorNome,
    required this.indicadorCodigo,
    required this.dataInicial,
    required this.dataFinal,
    required this.minimo,
    required this.maximo,
    required this.media,
    required this.variacaoPercentual,
    required this.desvioPadrao,
    required this.mediaMovel3,
    required this.quantidade,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String observacao;
  final String indicadorNome;
  final int indicadorCodigo;
  final String dataInicial;
  final String dataFinal;
  final double minimo;
  final double maximo;
  final double media;
  final double variacaoPercentual;
  final double desvioPadrao;
  final double mediaMovel3;
  final int quantidade;
  final DateTime? criadoEm;

  factory AnaliseSalva.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final estatisticas =
        (data['estatisticas'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final criadoEm = data['criadoEm'];

    return AnaliseSalva(
      id: doc.id,
      nome: (data['nome'] ?? '').toString(),
      observacao: (data['observacao'] ?? '').toString(),
      indicadorNome: (data['indicadorNome'] ?? '').toString(),
      indicadorCodigo: _readInt(data['indicadorCodigo']),
      dataInicial: (data['dataInicial'] ?? '').toString(),
      dataFinal: (data['dataFinal'] ?? '').toString(),
      minimo: _readDouble(estatisticas['minimo']),
      maximo: _readDouble(estatisticas['maximo']),
      media: _readDouble(estatisticas['media']),
      variacaoPercentual: _readDouble(estatisticas['variacaoPercentual']),
      desvioPadrao: _readDouble(estatisticas['desvioPadrao']),
      mediaMovel3: _readDouble(estatisticas['mediaMovel3']),
      quantidade: _readInt(estatisticas['quantidade']),
      criadoEm: criadoEm is Timestamp ? criadoEm.toDate() : null,
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
