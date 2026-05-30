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
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('indicadores');

  void _abrirAnalisesSalvas() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AnalisesSalvasScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _colecao.orderBy('nome').snapshots(),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _MensagemCentral(
                icon: Icons.error_outline_rounded,
                titulo: 'Erro ao carregar indicadores',
                texto: snapshot.error.toString(),
              );
            }

            final indicadores =
                snapshot.data?.docs.map(Indicador.fromDoc).toList() ?? [];

            if (indicadores.isEmpty) {
              return const _MensagemCentral(
                icon: Icons.dataset_outlined,
                titulo: 'Nenhum indicador cadastrado',
                texto: 'Nenhum indicador encontrado.',
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(totalIndicadores: indicadores.length),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: _BotaoAnalisesSalvas(
                      onPressed: _abrirAnalisesSalvas,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _PainelIndicadores(
                      child: Column(
                        children: [
                          for (int i = 0; i < indicadores.length; i++) ...[
                            _IndicadorCard(indicador: indicadores[i]),
                            if (i != indicadores.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalIndicadores});

  final int totalIndicadores;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Container(
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
              color: colorScheme.primary.withOpacity(0.28),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Monitor de Indicadores Econômicos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.query_stats_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Analise e visualização de dados macroeconômicos brasileiros',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _HeaderBadge(
                  icon: Icons.timeline_rounded,
                  texto: '$totalIndicadores ativos',
                ),
                const SizedBox(width: 10),
                const _HeaderBadge(
                  icon: Icons.auto_graph_rounded,
                  texto: 'BCB SGS',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoAnalisesSalvas extends StatelessWidget {
  const _BotaoAnalisesSalvas({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: 250,
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.bookmark_rounded),
          label: const Text(
            'Ver análises salvas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelIndicadores extends StatelessWidget {
  const _PainelIndicadores({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                const SizedBox(width: 70),
                Text(
                  'Indicador',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.black.withOpacity(0.45),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Valor atual',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.black.withOpacity(0.45),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          child,
        ],
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
  bool _hover = false;

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
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConsultaScreen(indicador: widget.indicador),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.045)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.indicador.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'SGS ${widget.indicador.codigo}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }

                  final valor = snapshot.data;
                  if (valor == null) {
                    return Text(
                      'Sem dados',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatarNumero(valor.valor),
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valor.dataFormatada,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(0.48),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 24),
              Icon(Icons.chevron_right_rounded, color: Colors.black),
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

class _MensagemCentral extends StatelessWidget {
  const _MensagemCentral({
    required this.icon,
    required this.titulo,
    required this.texto,
  });

  final IconData icon;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(texto, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
