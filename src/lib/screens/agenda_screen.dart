import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/agendamento.dart';
import '../widgets/agendamento_tile.dart';
import 'novo_agendamento_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});
  Future<void> _formulario(
    BuildContext context, [
    Agendamento? agendamento,
  ]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => NovoAgendamentoScreen(agendamento: agendamento),
      ),
    );
  }

  Future<void> _excluir(BuildContext context, Agendamento agendamento) async {
    final repo = AppScope.read(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: Text(
          'Deseja excluir o agendamento de ${agendamento.petNome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await repo.excluirAgendamento(agendamento.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento excluído com sucesso!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: repo.agendamentos.isEmpty
          ? const Center(child: Text('Nenhum agendamento cadastrado.'))
          : ListView.builder(
              itemCount: repo.agendamentos.length,
              itemBuilder: (_, i) {
                final a = repo.agendamentos[i];
                return AgendamentoTile(
                  agendamento: a,
                  onEditar: repo.podeGravar
                      ? () => _formulario(context, a)
                      : null,
                  onExcluir: repo.podeGravar
                      ? () => _excluir(context, a)
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_agenda',
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
        onPressed: repo.podeGravar ? () => _formulario(context) : null,
      ),
    );
  }
}
