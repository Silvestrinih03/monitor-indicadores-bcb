import 'package:flutter/material.dart';

import '../models/indicador.dart';
import '../models/indicador_valor.dart';
import '../services/bcb_service.dart';
import 'analise_screen.dart';

class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({
    super.key,
    required this.indicador,
  });

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

    final dataInicial =
        IndicadorValor.formatoBcb.parseStrict(_dataInicialController.text);
    final dataFinal = IndicadorValor.formatoBcb.parseStrict(_dataFinalController.text);

    if (dataInicial.isAfter(dataFinal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data inicial deve ser anterior a data final.')),
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
        title: const Text('Consulta'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    indicador.nome,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Codigo SGS ${indicador.codigo}'
                    '${indicador.unidade.isEmpty ? '' : ' | ${indicador.unidade}'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dataInicialController,
                          readOnly: true,
                          validator: _validarData,
                          decoration: InputDecoration(
                            labelText: 'Data inicial',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: 'Escolher data inicial',
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _selecionarData(_dataInicialController),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dataFinalController,
                          readOnly: true,
                          validator: _validarData,
                          decoration: InputDecoration(
                            labelText: 'Data final',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: 'Escolher data final',
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _selecionarData(_dataFinalController),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _consultar,
                      icon: const Icon(Icons.search),
                      label: const Text('Consultar periodo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(item.dataFormatada),
                      trailing: Text(
                        item.valor.toStringAsFixed(4),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
  const _ResultadoMensagem({
    required this.icon,
    required this.texto,
  });

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
