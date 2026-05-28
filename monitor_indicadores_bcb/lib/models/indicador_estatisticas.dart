import 'dart:math' as math;

import 'indicador_valor.dart';

class IndicadorEstatisticas {
  const IndicadorEstatisticas({
    required this.minimo,
    required this.maximo,
    required this.media,
    required this.mediaMovel3,
    required this.variacaoPercentual,
    required this.desvioPadrao,
    required this.quantidade,
  });

  final double minimo;
  final double maximo;
  final double media;
  final double mediaMovel3;
  final double variacaoPercentual;
  final double desvioPadrao;
  final int quantidade;

  factory IndicadorEstatisticas.fromValores(List<IndicadorValor> valores) {
    if (valores.isEmpty) {
      throw ArgumentError('Nao ha dados para calcular estatisticas.');
    }

    final numeros = valores.map((item) => item.valor).toList();
    final minimo = numeros.reduce(math.min);
    final maximo = numeros.reduce(math.max);
    final media = numeros.reduce((a, b) => a + b) / numeros.length;
    final primeiro = numeros.first;
    final ultimo = numeros.last;
    final variacaoPercentual = primeiro == 0 ? 0.0 : ((ultimo - primeiro) / primeiro) * 100;
    final variancia = numeros
            .map((valor) => math.pow(valor - media, 2).toDouble())
            .reduce((a, b) => a + b) /
        numeros.length;
    final ultimosTres = numeros.length >= 3 ? numeros.sublist(numeros.length - 3) : numeros;
    final mediaMovel3 = ultimosTres.reduce((a, b) => a + b) / ultimosTres.length;

    return IndicadorEstatisticas(
      minimo: minimo,
      maximo: maximo,
      media: media,
      mediaMovel3: mediaMovel3,
      variacaoPercentual: variacaoPercentual,
      desvioPadrao: math.sqrt(variancia),
      quantidade: numeros.length,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'minimo': minimo,
      'maximo': maximo,
      'media': media,
      'mediaMovel3': mediaMovel3,
      'variacaoPercentual': variacaoPercentual,
      'desvioPadrao': desvioPadrao,
      'quantidade': quantidade,
    };
  }
}
