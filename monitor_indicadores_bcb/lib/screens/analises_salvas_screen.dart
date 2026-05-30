import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analise_draft.dart';
import '../models/analise_salva.dart';

class AnalisesSalvasScreen extends StatefulWidget {
  const AnalisesSalvasScreen({super.key, this.draft});

  final AnaliseDraft? draft;

  @override
  State<AnalisesSalvasScreen> createState() => _AnalisesSalvasScreenState();
}

class _AnalisesSalvasScreenState extends State<AnalisesSalvasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _salvando = false;

  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('analises');

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.draft != null) {
        _abrirDialogSalvarAnalise();
      }
    });
  }

  Future<void> _abrirDialogSalvarAnalise() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar nova análise'),
          content: Form(
            key: _formKey,
            child: SizedBox(
              width: 420,
              child: TextFormField(
                controller: _nomeController,
                validator: _validarNome,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Nome da análise',
                  hintText: 'Ex: Dólar em maio de 2026',
                  filled: true,
                  fillColor: const Color(0xFFF4F6FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: _salvando
                  ? null
                  : () async {
                      final salvou = await _salvarAnalise();
                      if (salvou && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _salvarAnalise() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final draft = widget.draft;
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abra uma consulta analisada para salvar.'),
        ),
      );
      return false;
    }

    setState(() => _salvando = true);

    try {
      final ultimoValor = draft.valores.isEmpty
          ? 0.0
          : draft.valores.last.valor;
      final variacao = draft.estatisticas.variacaoPercentual;
      final direcao = variacao >= 0 ? 'alta' : 'queda';
      final intensidade = variacao.abs() >= 5
          ? 'forte'
          : variacao.abs() >= 2
          ? 'moderada'
          : 'leve';

      final conclusao =
          '${draft.indicador.nome} apresentou $direcao $intensidade de ${variacao.abs().toStringAsFixed(2)}%. \n'
          'O menor valor foi ${draft.estatisticas.minimo.toStringAsFixed(4)} e o maior foi ${draft.estatisticas.maximo.toStringAsFixed(4)}. \n'
          'A média ficou em ${draft.estatisticas.media.toStringAsFixed(4)}, com desvio padrão de ${draft.estatisticas.desvioPadrao.toStringAsFixed(4)}.';

      await _colecao.add({
        'nome': _nomeController.text.trim(),
        'indicadorNome': draft.indicador.nome,
        'indicadorCodigo': draft.indicador.codigo,
        'dataInicial': draft.dataInicial,
        'dataFinal': draft.dataFinal,
        'estatisticas': {
          'ultimoValor': ultimoValor,
          'minimo': draft.estatisticas.minimo,
          'maximo': draft.estatisticas.maximo,
          'media': draft.estatisticas.media,
          'variacaoPercentual': draft.estatisticas.variacaoPercentual,
          'desvioPadrao': draft.estatisticas.desvioPadrao,
          'quantidade': draft.valores.length,
        },
        'valores': draft.valores.map((item) {
          return {'data': item.dataFormatada, 'valor': item.valor};
        }).toList(),
        'conclusao': conclusao,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      _nomeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Análise salva com sucesso.')),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar análise: $error')),
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _confirmarExclusao(AnaliseSalva analise) async {
    final confirmado =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir analise?'),
              content: Text(
                'A analise "${analise.nome}" sera removida do Firestore.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmado) {
      return;
    }

    try {
      await _colecao.doc(analise.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Analise excluida.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $error')));
      }
    }
  }

  String? _validarNome(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return 'Informe um nome';
    }
    if (texto.length < 3) {
      return 'Minimo 3 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Analises salvas',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Historico',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _colecao.orderBy('criadoEm', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _MensagemLista(
                  icon: Icons.error_outline,
                  texto: 'Erro ao carregar analises: ${snapshot.error}',
                );
              }

              final analises =
                  snapshot.data?.docs.map(AnaliseSalva.fromDoc).toList() ?? [];

              if (analises.isEmpty) {
                return const _MensagemLista(
                  icon: Icons.bookmark_border,
                  texto: 'Nenhuma analise salva.',
                );
              }

              return ListView.builder(
                itemCount: analises.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final analise = analises[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnaliseSalvaCard(
                      analise: analise,
                      onDelete: () => _confirmarExclusao(analise),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnaliseSalvaCard extends StatelessWidget {
  const _AnaliseSalvaCard({required this.analise, required this.onDelete});

  final AnaliseSalva analise;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final criadoEm = analise.criadoEm == null
        ? 'Processando data'
        : DateFormat('dd/MM/yyyy HH:mm').format(analise.criadoEm!);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analise.nome,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analise.indicadorNome,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${analise.dataInicial} até ${analise.dataFinal}',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir análise',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Último',
                value: analise.ultimoValor.toStringAsFixed(4),
              ),
              _InfoChip(
                label: 'Média',
                value: analise.media.toStringAsFixed(4),
              ),
              _InfoChip(
                label: 'Mínimo',
                value: analise.minimo.toStringAsFixed(4),
              ),
              _InfoChip(
                label: 'Máximo',
                value: analise.maximo.toStringAsFixed(4),
              ),
              _InfoChip(
                label: 'Variação',
                value: '${analise.variacaoPercentual.toStringAsFixed(2)}%',
              ),
              _InfoChip(label: 'Registros', value: '${analise.quantidade}'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              analise.conclusao,
              style: TextStyle(
                color: Colors.black.withOpacity(0.68),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.black.withOpacity(0.42),
              ),
              const SizedBox(width: 6),
              Text(
                criadoEm,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.48),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => _GraficoAnaliseDialog(analise: analise),
                  );
                },
                icon: const Icon(Icons.show_chart_rounded, size: 18),
                label: const Text('Gráfico'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class _GraficoAnaliseDialog extends StatelessWidget {
  const _GraficoAnaliseDialog({required this.analise});

  final AnaliseSalva analise;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < analise.valores.length; i++)
        FlSpot(i.toDouble(), (analise.valores[i]['valor'] as num).toDouble()),
    ];

    final margem = (analise.maximo - analise.minimo).abs() * 0.08;
    final minY = analise.minimo == analise.maximo
        ? analise.minimo - 1
        : analise.minimo - margem;
    final maxY = analise.minimo == analise.maximo
        ? analise.maximo + 1
        : analise.maximo + margem;

    return AlertDialog(
      title: Text(analise.nome),
      content: SizedBox(
        width: 720,
        height: 360,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, analise.valores.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.black.withOpacity(0.08), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: analise.media,
                  strokeWidth: 2,
                  dashArray: const [7, 5],
                ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: spots.length > 2,
                preventCurveOverShooting: true,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(show: spots.length <= 24),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MensagemLista extends StatelessWidget {
  const _MensagemLista({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
