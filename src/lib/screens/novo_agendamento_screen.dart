import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/agendamento.dart';
import '../models/cliente.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  final Agendamento? agendamento;

  const NovoAgendamentoScreen({
    super.key,
    this.agendamento,
  });

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  List<Cliente> _clientes = [];

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  int? _petSelecionado;
  String _servico = 'Banho';

  late DateTime _data;
  late TimeOfDay _horario;

  bool get _editando => widget.agendamento != null;

  @override
  void initState() {
    super.initState();

    final agendamento = widget.agendamento;

    _petSelecionado = agendamento?.petId;
    _servico = agendamento?.servico ?? 'Banho';

    _data = agendamento?.dataHora ?? DateTime.now();
    _horario = TimeOfDay.fromDateTime(_data);

    _carregarClientes();
  }

  // Recupera os clientes e pets cadastrados.
  Future<void> _carregarClientes() async {
    try {
      final clientes = await DatabaseHelper.instancia.listarClientes();

      if (!mounted) return;

      setState(() {
        _clientes = clientes;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os pets: $erro';
        _carregando = false;
      });
    }
  }

  // Abre o calendário para selecionar uma data.
  Future<void> _escolherData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (novaData != null && mounted) {
      setState(() => _data = novaData);
    }
  }

  // Abre o seletor de horário.
  Future<void> _escolherHorario() async {
    final novoHorario = await showTimePicker(
      context: context,
      initialTime: _horario,
    );

    if (novoHorario != null && mounted) {
      setState(() => _horario = novoHorario);
    }
  }

  // Cria ou atualiza um agendamento no SQLite.
  Future<void> _salvar() async {
    if (_petSelecionado == null || _salvando) return;

    setState(() => _salvando = true);

    try {
      final dataHora = DateTime(
        _data.year,
        _data.month,
        _data.day,
        _horario.hour,
        _horario.minute,
      );

      await DatabaseHelper.instancia.salvarAgendamento(
        id: widget.agendamento?.id,
        petId: _petSelecionado!,
        dataHora: dataHora,
        servico: _servico,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Agendamento atualizado com sucesso!'
                : 'Agendamento salvo com sucesso!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      final mensagem = erro is StateError
          ? erro.message
          : 'Não foi possível salvar o agendamento.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opcoesPets = <DropdownMenuItem<int>>[
      for (final cliente in _clientes)
        for (final pet in cliente.pets)
          if (pet.id != null)
            DropdownMenuItem<int>(
              value: pet.id,
              child: Text(
                '${pet.nome} (${cliente.nome})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
    ];

    final dataFormatada =
        '${_data.day.toString().padLeft(2, '0')}/'
        '${_data.month.toString().padLeft(2, '0')}/'
        '${_data.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar Agendamento' : 'Novo Agendamento',
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Text(_erro!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (opcoesPets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Nenhum pet cadastrado. '
                        'Cadastre um cliente e seu pet antes de agendar.',
                      ),
                    ),
                  DropdownButtonFormField<int>(
                    initialValue: _petSelecionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cliente / Pet',
                      border: OutlineInputBorder(),
                    ),
                    items: opcoesPets,
                    onChanged: opcoesPets.isEmpty
                        ? null
                        : (valor) {
                            setState(() => _petSelecionado = valor);
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _servico,
                    decoration: const InputDecoration(
                      labelText: 'Serviço',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Banho', 'Tosa', 'Banho e Tosa']
                        .map(
                          (servico) => DropdownMenuItem(
                            value: servico,
                            child: Text(servico),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() => _servico = valor);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Data: $dataFormatada'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        onPressed: _escolherData,
                        child: const Text('Escolher data'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Horário: ${_horario.format(context)}',
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        onPressed: _escolherHorario,
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
                    onPressed: _salvando || _petSelecionado == null
                        ? null
                        : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editando
                                ? 'Salvar Alterações'
                                : 'Confirmar Agendamento',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
