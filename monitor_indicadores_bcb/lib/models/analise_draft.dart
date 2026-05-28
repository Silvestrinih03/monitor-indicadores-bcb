import 'indicador.dart';
import 'indicador_estatisticas.dart';
import 'indicador_valor.dart';

class AnaliseDraft {
  const AnaliseDraft({
    required this.indicador,
    required this.dataInicial,
    required this.dataFinal,
    required this.valores,
    required this.estatisticas,
  });

  final Indicador indicador;
  final String dataInicial;
  final String dataFinal;
  final List<IndicadorValor> valores;
  final IndicadorEstatisticas estatisticas;
}
