import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  bool _salvando = false;
  String? _clienteSelecionado;
  String _servico = 'Banho';
  TimeOfDay _horario = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _clienteSelecionado,
              decoration: const InputDecoration(
                labelText: 'Cliente / Pet',
                border: OutlineInputBorder(),
              ),
              items: mockClientes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.nome,
                      child: Text(
                        '${c.pets.isNotEmpty ? c.pets.first.nome : "?"} (${c.nome})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _clienteSelecionado = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _servico,
              decoration: const InputDecoration(
                labelText: 'Serviço',
                border: OutlineInputBorder(),
              ),
              items: [
                'Banho',
                'Tosa',
                'Banho e Tosa',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _servico = v!),
            ),
            const SizedBox(height: 16),
            //seletor de horario nativo do Flutter
            Row(
              children: [
                Expanded(child: Text('Horário: ${_horario.format(context)}')),
                TextButton(
                  onPressed: () async {
                    final novoHorario = await showTimePicker(
                      context: context,
                      initialTime: _horario,
                    );
                    if (novoHorario != null) {
                      setState(() => _horario = novoHorario);
                    }
                  },
                  child: const Text('Escolher horário'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF0B6374),
              ),
              onPressed: (_clienteSelecionado == null || _salvando)
                  ? null //desabilita se nao tiver cliente selecionado ou se já estiver salvando
                  : () async {
                      setState(() => _salvando = true);

                      //simula uma operação, ex: salvar no banco/servidor
                      await Future.delayed(const Duration(milliseconds: 800));

                      if (!context.mounted) return;
                      setState(() => _salvando = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Agendamento salvo com sucesso!'),
                        ),
                      );
                      Navigator.pop(context);
                    },
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirmar Agendamento',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
