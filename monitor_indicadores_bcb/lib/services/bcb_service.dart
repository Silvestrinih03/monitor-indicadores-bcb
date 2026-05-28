import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/indicador.dart';
import '../models/indicador_valor.dart';

class BcbService {
  const BcbService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<IndicadorValor>> buscarValores({
    required Indicador indicador,
    required DateTime dataInicial,
    required DateTime dataFinal,
  }) async {
    if (indicador.codigo <= 0) {
      throw Exception('Codigo SGS invalido para ${indicador.nome}.');
    }
    if (dataInicial.isAfter(dataFinal)) {
      throw Exception('A data inicial nao pode ser maior que a data final.');
    }

    final uri = Uri.https(
      'api.bcb.gov.br',
      '/dados/serie/bcdata.sgs.${indicador.codigo}/dados',
      {
        'formato': 'json',
        'dataInicial': IndicadorValor.formatoBcb.format(dataInicial),
        'dataFinal': IndicadorValor.formatoBcb.format(dataFinal),
      },
    );
    final client = _client ?? http.Client();

    try {
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw Exception('API do BCB retornou status ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Resposta inesperada da API do BCB.');
      }

      final valores = decoded
          .cast<Map<String, dynamic>>()
          .map(IndicadorValor.fromJson)
          .toList()
        ..sort((a, b) => a.data.compareTo(b.data));

      return valores;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<IndicadorValor?> buscarValorMaisRecente(Indicador indicador) async {
    final dataFinal = DateTime.now();
    final dataInicial = DateTime(
      dataFinal.year - 1,
      dataFinal.month,
      dataFinal.day,
    );
    final valores = await buscarValores(
      indicador: indicador,
      dataInicial: dataInicial,
      dataFinal: dataFinal,
    );

    return valores.isEmpty ? null : valores.last;
  }
}
