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
    final ultimoValor = valores.isEmpty ? 0.0 : valores.last.valor;
    final variacao = estatisticas.variacaoPercentual;
    final subiu = variacao >= 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Análise',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroAnalise(
            indicador: indicador,
            dataInicial: dataInicial,
            dataFinal: dataFinal,
            totalRegistros: valores.length,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCardPremium(
                icon: Icons.stacked_line_chart_rounded,
                titulo: 'Último valor',
                valor: _formatarNumero(ultimoValor),
                descricao: 'Valor mais recente retornado pela API.',
                destaque: true,
              ),
              _StatCardPremium(
                icon: Icons.south_east_rounded,
                titulo: 'Mínimo',
                valor: _formatarNumero(estatisticas.minimo),
                descricao: 'Menor valor observado no período.',
              ),
              _StatCardPremium(
                icon: Icons.north_east_rounded,
                titulo: 'Máximo',
                valor: _formatarNumero(estatisticas.maximo),
                descricao: 'Maior valor observado no período.',
              ),
              _StatCardPremium(
                icon: Icons.functions_rounded,
                titulo: 'Média',
                valor: _formatarNumero(estatisticas.media),
                descricao: 'Valor médio considerando todos os registros.',
              ),
              _StatCardPremium(
                icon: subiu
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                titulo: 'Variação %',
                valor: '${estatisticas.variacaoPercentual.toStringAsFixed(2)}%',
                descricao:
                    'Diferença percentual entre o primeiro e o último valor.',
              ),
              _StatCardPremium(
                icon: Icons.waves_rounded,
                titulo: 'Desvio padrão',
                valor: _formatarNumero(estatisticas.desvioPadrao),
                descricao:
                    'Mede o quanto os valores oscilaram ao longo do período.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            indicador: indicador,
            valores: valores,
            estatisticas: estatisticas,
          ),
          const SizedBox(height: 16),
          _ConclusaoAnalise(
            estatisticas: estatisticas,
            indicador: indicador,
            dataInicial: dataInicial,
            dataFinal: dataFinal,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text(
                'Salvar análise',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatarNumero(double valor) {
    if (valor.abs() >= 100) {
      return valor.toStringAsFixed(2);
    }
    return valor.toStringAsFixed(4);
  }
}

class _HeroAnalise extends StatelessWidget {
  const _HeroAnalise({
    required this.indicador,
    required this.dataInicial,
    required this.dataFinal,
    required this.totalRegistros,
  });

  final Indicador indicador;
  final String dataInicial;
  final String dataFinal;
  final int totalRegistros;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 18),
          Text(
            indicador.nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$dataInicial até $dataFinal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(texto: 'SGS ${indicador.codigo}'),
              _HeroBadge(
                texto:
                    '$totalRegistros ${totalRegistros == 1 ? "registro encontrado" : "registros encontrados"}',
              ),
              if (indicador.unidade.isNotEmpty)
                _HeroBadge(texto: indicador.unidade),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.indicador,
    required this.valores,
    required this.estatisticas,
  });

  final Indicador indicador;
  final List<IndicadorValor> valores;
  final IndicadorEstatisticas estatisticas;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução no período',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Linha média destacada para facilitar a leitura da tendência.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black.withOpacity(0.48),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: LineChart(_chartData(context))),
        ],
      ),
    );
  }

  LineChartData _chartData(BuildContext context) {
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
            FlLine(color: Colors.black.withOpacity(0.06), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
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
            dashArray: const [7, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => 'Média',
              style: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (items) {
            return items.map((item) {
              final index = item.x.round();
              final data = index >= 0 && index < valores.length
                  ? valores[index].dataFormatada
                  : '';
              return LineTooltipItem(
                '$data\n${item.y.toStringAsFixed(4)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: valores.length > 2,
          preventCurveOverShooting: true,
          color: colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: valores.length <= 24),
          belowBarData: BarAreaData(
            show: true,
            color: colorScheme.primary.withOpacity(0.12),
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
      child: Text(
        data,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.black.withOpacity(0.45),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatarEixo(double valor) {
    if (valor.abs() >= 100) {
      return valor.toStringAsFixed(0);
    }
    return valor.toStringAsFixed(2);
  }
}

class _StatCardPremium extends StatelessWidget {
  const _StatCardPremium({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.descricao,
    this.destaque = false,
  });

  final IconData icon;
  final String titulo;
  final String valor;
  final String descricao;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: destaque ? colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: destaque ? Colors.white : colorScheme.primary),
              const Spacer(),
              Tooltip(
                message: descricao,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: destaque ? Colors.white70 : Colors.black45,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: destaque
                      ? Colors.white.withOpacity(0.72)
                      : Colors.black.withOpacity(0.48),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: TextStyle(
                    color: destaque ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConclusaoAnalise extends StatelessWidget {
  const _ConclusaoAnalise({
    required this.estatisticas,
    required this.indicador,
    required this.dataInicial,
    required this.dataFinal,
  });

  final IndicadorEstatisticas estatisticas;
  final Indicador indicador;
  final String dataInicial;
  final String dataFinal;

  @override
  Widget build(BuildContext context) {
    final variacao = estatisticas.variacaoPercentual;
    final direcao = variacao >= 0 ? 'alta' : 'queda';
    final intensidade = variacao.abs() >= 5
        ? 'forte'
        : variacao.abs() >= 2
        ? 'moderada'
        : 'leve';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded),
              const SizedBox(width: 8),
              Text(
                'Conclusão da Análise',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResumoLinha(
                titulo: 'Tendência',
                texto:
                    '${indicador.nome} apresentou $direcao $intensidade de ${variacao.abs().toStringAsFixed(2)}%.',
              ),
              const SizedBox(height: 10),
              _ResumoLinha(
                titulo: 'Amplitude',
                texto:
                    'O menor valor foi ${_formatarNumero(estatisticas.minimo)} e o maior foi ${_formatarNumero(estatisticas.maximo)}.',
              ),
              const SizedBox(height: 10),
              _ResumoLinha(
                titulo: 'Média',
                texto: '${_formatarNumero(estatisticas.media)}',
              ),
              const SizedBox(height: 10),
              _ResumoLinha(
                titulo: 'Desvio Padrão',
                texto: '${_formatarNumero(estatisticas.desvioPadrao)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarNumero(double valor) {
    if (valor.abs() >= 100) {
      return valor.toStringAsFixed(2);
    }
    return valor.toStringAsFixed(4);
  }
}

class _ResumoLinha extends StatelessWidget {
  const _ResumoLinha({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$titulo: ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: texto),
        ],
      ),
      style: TextStyle(
        color: Colors.black.withOpacity(0.68),
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
