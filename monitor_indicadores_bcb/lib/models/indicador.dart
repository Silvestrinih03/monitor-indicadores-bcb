import 'package:cloud_firestore/cloud_firestore.dart';

class Indicador {
  const Indicador({
    required this.id,
    required this.nome,
    required this.codigo,
    this.unidade = '',
    this.descricao = '',
  });

  final String id;
  final String nome;
  final int codigo;
  final String unidade;
  final String descricao;

  factory Indicador.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final codigoBruto = data['codigo'] ?? data['code'] ?? data['sgs'];

    return Indicador(
      id: doc.id,
      nome: (data['nome'] ?? data['name'] ?? 'Indicador sem nome').toString(),
      codigo: _parseCodigo(codigoBruto),
      unidade: (data['unidade'] ?? '').toString(),
      descricao: (data['descricao'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'codigo': codigo,
      'unidade': unidade,
      'descricao': descricao,
    };
  }

  static int _parseCodigo(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
