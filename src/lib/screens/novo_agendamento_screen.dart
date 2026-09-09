import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
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
                  .map((c) => DropdownMenuItem(
                        value: c.nome,
                        child: Text(
                            '${c.pets.isNotEmpty ? c.pets.first.nome : "?"} (${c.nome})'),
                      ))
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
              items: ['Banho', 'Tosa', 'Banho e Tosa']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
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
              onPressed: _clienteSelecionado == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Agendamento salvo (simulado)!')),
                      );
                      Navigator.pop(context);
                    },
              child: const Text(
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