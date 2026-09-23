import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/agendamento_tile.dart';
import 'novo_agendamento_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de Hoje')),
      body: mockAgendamentos.isEmpty
          ? const Center(child: Text('Nenhum agendamento para hoje.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: mockAgendamentos.length,
              itemBuilder: (context, index) {
                return AgendamentoTile(agendamento: mockAgendamentos[index]);
              },
            ),
      floatingActionButton: Semantics(
        hint: 'Abre o formulário para marcar um novo horário',
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Novo Agendamento'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NovoAgendamentoScreen()),
            );
          },
        ),
      ),
    );
  }
}
