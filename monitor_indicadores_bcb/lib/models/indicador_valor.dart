import 'package:intl/intl.dart';

class IndicadorValor {
  IndicadorValor({
    required this.data,
    required this.valor,
  });

  static final DateFormat formatoBcb = DateFormat('dd/MM/yyyy');

  final DateTime data;
  final double valor;

  factory IndicadorValor.fromJson(Map<String, dynamic> json) {
    final valorNormalizado = json['valor']?.toString().replaceAll(',', '.');

    return IndicadorValor(
      data: formatoBcb.parseStrict(json['data'].toString()),
      valor: double.parse(valorNormalizado ?? '0'),
    );
  }

  String get dataFormatada => formatoBcb.format(data);
}
