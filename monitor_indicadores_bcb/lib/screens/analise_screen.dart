import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analise_draft.dart';
import '../models/indicador.dart';
import '../models/indicador_estatisticas.dart';
import '../models/indicador_valor.dart';
import 'analises_salvas_screen.dart';

class AnaliseScreen extends StatelessWidget {
  const AnaliseScreen({
    super.key,
    required this.indicador,
    required this.valores,
    required this.dataInicial,
    required this.dataFinal,
  });

  final Indicador indicador;
  final List<IndicadorValor> valores;
  final String dataInicial;
  final String dataFinal;

  @override
  Widget build(BuildContext context) {
    final estatisticas = IndicadorEstatisticas.fromValores(valores);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Análise',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            indicador.nome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text('$dataInicial ate $dataFinal | ${valores.length} pontos'),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 18, 12),
                child: LineChart(_chartData(context, estatisticas)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 720 ? 3 : 2,
            childAspectRatio: 1.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                icon: Icons.south_east,
                titulo: 'Minimo',
                valor: _formatarNumero(estatisticas.minimo),
              ),
              _StatCard(
                icon: Icons.north_east,
                titulo: 'Maximo',
                valor: _formatarNumero(estatisticas.maximo),
              ),
              _StatCard(
                icon: Icons.functions,
                titulo: 'Media',
                valor: _formatarNumero(estatisticas.media),
              ),
              _StatCard(
                icon: Icons.trending_up,
                titulo: 'Variacao',
                valor: '${estatisticas.variacaoPercentual.toStringAsFixed(2)}%',
              ),
              _StatCard(
                icon: Icons.waves,
                titulo: 'Desvio',
                valor: _formatarNumero(estatisticas.desvioPadrao),
              ),
              _StatCard(
                icon: Icons.timeline,
                titulo: 'Media movel 3',
                valor: _formatarNumero(estatisticas.mediaMovel3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalisesSalvasScreen(
                    draft: AnaliseDraft(
                      indicador: indicador,
                      dataInicial: dataInicial,
                      dataFinal: dataFinal,
                      valores: valores,
                      estatisticas: estatisticas,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Salvar análise'),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(
    BuildContext context,
    IndicadorEstatisticas estatisticas,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = [
      for (var index = 0; index < valores.length; index++)
        FlSpot(index.toDouble(), valores[index].valor),
    ];
    final margem = (estatisticas.maximo - estatisticas.minimo).abs() * 0.08;
    final minY = estatisticas.minimo == estatisticas.maximo
        ? estatisticas.minimo - 1
        : estatisticas.minimo - margem;
    final maxY = estatisticas.minimo == estatisticas.maximo
        ? estatisticas.maximo + 1
        : estatisticas.maximo + margem;
    final intervaloX = math.max(1, (valores.length / 4).ceil()).toDouble();

    return LineChartData(
      minX: 0,
      maxX: math.max(1, valores.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: colorScheme.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: intervaloX,
            getTitlesWidget: (value, meta) =>
                _bottomTitle(context, value, meta),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                _formatarEixo(value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: estatisticas.media,
            color: colorScheme.secondary,
            strokeWidth: 2,
            dashArray: const [6, 4],
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: valores.length > 2,
          preventCurveOverShooting: true,
          color: colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: valores.length <= 24),
          belowBarData: BarAreaData(
            show: true,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  Widget _bottomTitle(BuildContext context, double value, TitleMeta meta) {
    final index = value.round();
    if (index < 0 || index >= valores.length) {
      return const SizedBox.shrink();
    }

    final data = valores[index].dataFormatada.substring(0, 5);
    return SideTitleWidget(
      meta: meta,
      child: Text(data, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  String _formatarNumero(double valor) {
    if (valor.abs() >= 100) {
      return valor.toStringAsFixed(2);
    }
    return valor.toStringAsFixed(4);
  }

  String _formatarEixo(double valor) {
    if (valor.abs() >= 100) {
      return valor.toStringAsFixed(0);
    }
    return valor.toStringAsFixed(2);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colorScheme.primary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.bodySmall),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valor,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
