import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';

import '../models/indicador.dart';
import '../models/indicador_valor.dart';
import '../services/bcb_service.dart';
import 'analise_screen.dart';

class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key, required this.indicador});

  final Indicador indicador;

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataInicialController = TextEditingController();
  final _dataFinalController = TextEditingController();
  final _bcbService = const BcbService();

  Future<List<IndicadorValor>>? _consultaFuture;

  @override
  void dispose() {
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(1995),
      lastDate: hoje,
    );

    if (selecionada != null) {
      setState(() {
        controller.text = IndicadorValor.formatoBcb.format(selecionada);
      });
    }
  }

  void _consultar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dataInicial = IndicadorValor.formatoBcb.parseStrict(
      _dataInicialController.text,
    );
    final dataFinal = IndicadorValor.formatoBcb.parseStrict(
      _dataFinalController.text,
    );

    if (dataInicial.isAfter(dataFinal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data inicial deve ser anterior a data final.'),
        ),
      );
      return;
    }

    setState(() {
      _consultaFuture = _bcbService.buscarValores(
        indicador: widget.indicador,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
      );
    });
  }

  String? _validarData(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    try {
      IndicadorValor.formatoBcb.parseStrict(value);
      return null;
    } catch (_) {
      return 'Use DD/MM/AAAA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicador = widget.indicador;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Consulta',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: Container(
        color: const Color(0xFFF4F6FB),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        indicador.nome,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'SGS ${indicador.codigo}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Período da consulta',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dataInicialController,
                              keyboardType: TextInputType.datetime,
                              validator: _validarData,
                              inputFormatters: [
                                MaskedInputFormatter('##/##/####'),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Data inicial *',
                                hintText: 'DD/MM/AAAA',
                                filled: true,
                                fillColor: const Color(0xFFF4F6FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month_rounded,
                                  ),
                                  onPressed: () =>
                                      _selecionarData(_dataInicialController),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dataFinalController,
                              keyboardType: TextInputType.datetime,
                              validator: _validarData,
                              inputFormatters: [
                                MaskedInputFormatter('##/##/####'),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Data final *',
                                hintText: 'DD/MM/AAAA',
                                filled: true,
                                fillColor: const Color(0xFFF4F6FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month_rounded,
                                  ),
                                  onPressed: () =>
                                      _selecionarData(_dataFinalController),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _consultar,
                          icon: const Icon(Icons.search_rounded),
                          label: const Text(
                            'Consultar período',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _ResultadoConsulta(
                future: _consultaFuture,
                indicador: indicador,
                dataInicial: _dataInicialController.text,
                dataFinal: _dataFinalController.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoConsulta extends StatelessWidget {
  const _ResultadoConsulta({
    required this.future,
    required this.indicador,
    required this.dataInicial,
    required this.dataFinal,
  });

  final Future<List<IndicadorValor>>? future;
  final Indicador indicador;
  final String dataInicial;
  final String dataFinal;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const Center(
        child: Text('Informe o periodo para consultar a API do Banco Central.'),
      );
    }

    return FutureBuilder<List<IndicadorValor>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ResultadoMensagem(
            icon: Icons.error_outline,
            texto: 'Erro ao consultar dados: ${snapshot.error}',
          );
        }

        final valores = snapshot.data ?? [];
        if (valores.isEmpty) {
          return const _ResultadoMensagem(
            icon: Icons.search_off,
            texto: 'Nenhum valor encontrado para o periodo informado.',
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${valores.length} registros encontrados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnaliseScreen(
                            indicador: indicador,
                            valores: valores,
                            dataInicial: dataInicial,
                            dataFinal: dataFinal,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights),
                    label: const Text('Analisar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: valores.length,
                itemBuilder: (context, index) {
                  final item = valores[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.dataFormatada,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          item.valor.toStringAsFixed(4),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultadoMensagem extends StatelessWidget {
  const _ResultadoMensagem({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
