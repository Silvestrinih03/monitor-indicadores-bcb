import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/indicador.dart';
import '../models/indicador_valor.dart';
import '../services/bcb_service.dart';
import 'analises_salvas_screen.dart';
import 'consulta_screen.dart';

class IndicadoresScreen extends StatefulWidget {
  const IndicadoresScreen({super.key});

  @override
  State<IndicadoresScreen> createState() => _IndicadoresScreenState();
}

class _IndicadoresScreenState extends State<IndicadoresScreen> {
  bool _criandoExemplos = false;

  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('indicadores');

  Future<void> _criarIndicadoresExemplo() async {
    setState(() => _criandoExemplos = true);

    final exemplos = [
      const Indicador(
        id: 'dolar',
        nome: 'Dolar comercial',
        codigo: 1,
        unidade: 'Reais',
        descricao: 'Taxa de cambio comercial para compra.',
      ),
      const Indicador(
        id: 'selic',
        nome: 'Taxa Selic',
        codigo: 11,
        unidade: '% a.d.',
        descricao: 'Taxa Selic diaria divulgada pelo Banco Central.',
      ),
      const Indicador(
        id: 'ipca',
        nome: 'IPCA',
        codigo: 433,
        unidade: '% a.m.',
        descricao: 'Indice de precos ao consumidor amplo.',
      ),
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final indicador in exemplos) {
        batch.set(_colecao.doc(indicador.id), indicador.toFirestore());
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indicadores de exemplo criados.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar exemplos: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _criandoExemplos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores BCB'),
        actions: [
          IconButton(
            tooltip: 'Analises salvas',
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalisesSalvasScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _colecao.orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MensagemCentral(
              icon: Icons.error_outline,
              titulo: 'Erro ao carregar indicadores',
              texto: snapshot.error.toString(),
            );
          }

          final indicadores =
              snapshot.data?.docs.map(Indicador.fromDoc).toList() ?? [];

          if (indicadores.isEmpty) {
            return _IndicadoresVazios(
              criandoExemplos: _criandoExemplos,
              onCriarExemplos: _criarIndicadoresExemplo,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: indicadores.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IndicadorCard(indicador: indicadores[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _IndicadorCard extends StatefulWidget {
  const _IndicadorCard({required this.indicador});

  final Indicador indicador;

  @override
  State<_IndicadorCard> createState() => _IndicadorCardState();
}

class _IndicadorCardState extends State<_IndicadorCard> {
  final BcbService _bcbService = const BcbService();
  late Future<IndicadorValor?> _valorMaisRecente;

  @override
  void initState() {
    super.initState();
    _valorMaisRecente = _bcbService.buscarValorMaisRecente(widget.indicador);
  }

  @override
  void didUpdateWidget(covariant _IndicadorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indicador.codigo != widget.indicador.codigo) {
      _valorMaisRecente = _bcbService.buscarValorMaisRecente(widget.indicador);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConsultaScreen(indicador: widget.indicador),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.show_chart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.indicador.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Codigo SGS ${widget.indicador.codigo}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<IndicadorValor?>(
                future: _valorMaisRecente,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Erro',
                      style: TextStyle(color: colorScheme.error),
                    );
                  }

                  final valor = snapshot.data;
                  if (valor == null) {
                    return const Text('Sem dados');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatarNumero(valor.valor),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        valor.dataFormatada,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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

class _IndicadoresVazios extends StatelessWidget {
  const _IndicadoresVazios({
    required this.criandoExemplos,
    required this.onCriarExemplos,
  });

  final bool criandoExemplos;
  final VoidCallback onCriarExemplos;

  @override
  Widget build(BuildContext context) {
    return _MensagemCentral(
      icon: Icons.dataset_outlined,
      titulo: 'Nenhum indicador cadastrado',
      texto:
          'A colecao indicadores deve ter documentos com nome, codigo, unidade e descricao.',
      acao: FilledButton.icon(
        onPressed: criandoExemplos ? null : onCriarExemplos,
        icon: criandoExemplos
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: const Text('Criar exemplos'),
      ),
    );
  }
}

class _MensagemCentral extends StatelessWidget {
  const _MensagemCentral({
    required this.icon,
    required this.titulo,
    required this.texto,
    this.acao,
  });

  final IconData icon;
  final String titulo;
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center),
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}
