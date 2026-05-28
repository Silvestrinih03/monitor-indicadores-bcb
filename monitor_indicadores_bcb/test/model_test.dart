import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_indicadores_bcb/models/indicador_estatisticas.dart';
import 'package:monitor_indicadores_bcb/models/indicador_valor.dart';

void main() {
  test('calcula estatisticas basicas do indicador', () {
    final valores = [
      IndicadorValor(data: DateTime(2026, 1, 1), valor: 10),
      IndicadorValor(data: DateTime(2026, 1, 2), valor: 12),
      IndicadorValor(data: DateTime(2026, 1, 3), valor: 14),
    ];

    final stats = IndicadorEstatisticas.fromValores(valores);

    expect(stats.minimo, 10);
    expect(stats.maximo, 14);
    expect(stats.media, 12);
    expect(stats.mediaMovel3, 12);
    expect(stats.variacaoPercentual, 40);
    expect(stats.quantidade, 3);
  });
}
