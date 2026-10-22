import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/agendamento.dart';
import '../widgets/agendamento_tile.dart';
import 'novo_agendamento_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Agendamento> _agendamentos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  // Recupera os agendamentos armazenados no SQLite.
  Future<void> _carregarAgendamentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final agendamentos = await DatabaseHelper.instancia.listarAgendamentos();

      if (!mounted) return;

      setState(() {
        _agendamentos = agendamentos;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os agendamentos: $erro';
        _carregando = false;
      });
    }
  }

  // Abre o formulário para cadastrar ou editar agendamentos.
  Future<void> _abrirFormulario({Agendamento? agendamento}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NovoAgendamentoScreen(
          agendamento: agendamento,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      await _carregarAgendamentos();
    }
  }

  // Solicita confirmação antes de excluir um agendamento.
  Future<void> _excluirAgendamento(Agendamento agendamento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: Text(
          'Deseja excluir o agendamento de '
          '${agendamento.petNome}? '
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true || agendamento.id == null) {
      return;
    }

    try {
      await DatabaseHelper.instancia.excluirAgendamento(
        agendamento.id!,
      );

      if (!mounted) return;

      await _carregarAgendamentos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento excluído com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível excluir o agendamento: $erro',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _erro != null
          ? Center(
              child: Text(_erro!),
            )
          : _agendamentos.isEmpty
          ? const Center(
              child: Text('Nenhum agendamento cadastrado.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _agendamentos.length,
              itemBuilder: (context, index) {
                final agendamento = _agendamentos[index];

                return AgendamentoTile(
                  agendamento: agendamento,
                  onEditar: () => _abrirFormulario(
                    agendamento: agendamento,
                  ),
                  onExcluir: () => _excluirAgendamento(
                    agendamento,
                  ),
                );
              },
            ),
      floatingActionButton: Semantics(
        label: 'Adicionar novo agendamento',
        button: true,
        hint: 'Abre o formulário para marcar um novo horário',
        child: FloatingActionButton.extended(
          heroTag: 'fab_agenda',
          icon: const Icon(Icons.add),
          label: const Text('Novo Agendamento'),
          onPressed: _abrirFormulario,
        ),
      ),
    );
  }
}
