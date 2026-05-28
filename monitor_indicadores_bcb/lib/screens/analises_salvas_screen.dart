import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analise_draft.dart';
import '../models/analise_salva.dart';

class AnalisesSalvasScreen extends StatefulWidget {
  const AnalisesSalvasScreen({
    super.key,
    this.draft,
  });

  final AnaliseDraft? draft;

  @override
  State<AnalisesSalvasScreen> createState() => _AnalisesSalvasScreenState();
}

class _AnalisesSalvasScreenState extends State<AnalisesSalvasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _salvando = false;

  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('analises');

  @override
  void dispose() {
    _nomeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAnalise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = widget.draft;
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abra uma consulta analisada para salvar.')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      await _colecao.add({
        'nome': _nomeController.text.trim(),
        'observacao': _observacaoController.text.trim(),
        'indicadorNome': draft.indicador.nome,
        'indicadorCodigo': draft.indicador.codigo,
        'dataInicial': draft.dataInicial,
        'dataFinal': draft.dataFinal,
        'estatisticas': draft.estatisticas.toFirestore(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      _nomeController.clear();
      _observacaoController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analise salva com sucesso.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar analise: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _confirmarExclusao(AnaliseSalva analise) async {
    final confirmado = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir analise?'),
              content: Text('A analise "${analise.nome}" sera removida do Firestore.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analise excluida.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $error')),
        );
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

  String? _validarObservacao(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return 'Informe uma observacao';
    }
    if (texto.length < 5) {
      return 'Minimo 5 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analises salvas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salvar nova analise',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      draft == null
                          ? 'Nenhuma analise selecionada no momento.'
                          : '${draft.indicador.nome} | ${draft.dataInicial} ate ${draft.dataFinal}',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomeController,
                      validator: _validarNome,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome da analise',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacaoController,
                      validator: _validarObservacao,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observacao do grupo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _salvando ? null : _salvarAnalise,
                        icon: _salvando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar no Firestore'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Historico',
            style: Theme.of(context).textTheme.titleLarge,
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
  const _AnaliseSalvaCard({
    required this.analise,
    required this.onDelete,
  });

  final AnaliseSalva analise;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final criadoEm = analise.criadoEm == null
        ? 'Processando data'
        : DateFormat('dd/MM/yyyy HH:mm').format(analise.criadoEm!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analise.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analise.indicadorNome} | ${analise.dataInicial} ate ${analise.dataFinal}',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Excluir analise',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(analise.observacao),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Media', value: analise.media.toStringAsFixed(4)),
                _InfoChip(label: 'Min', value: analise.minimo.toStringAsFixed(4)),
                _InfoChip(label: 'Max', value: analise.maximo.toStringAsFixed(4)),
                _InfoChip(
                  label: 'Variacao',
                  value: '${analise.variacaoPercentual.toStringAsFixed(2)}%',
                ),
                _InfoChip(label: 'Pontos', value: '${analise.quantidade}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              criadoEm,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label: $value'),
    );
  }
}

class _MensagemLista extends StatelessWidget {
  const _MensagemLista({
    required this.icon,
    required this.texto,
  });

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
