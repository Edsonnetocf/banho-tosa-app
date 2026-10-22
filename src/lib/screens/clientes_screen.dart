import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/cliente.dart';
import '../widgets/cliente_card.dart';
import 'cliente_form_screen.dart';
import 'pet_detalhes_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];
  String _busca = '';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  // Recupera os clientes armazenados no SQLite.
  Future<void> _carregarClientes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

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
        _erro = 'Não foi possível carregar os clientes: $erro';
        _carregando = false;
      });
    }
  }

  // Filtra os clientes pelo nome digitado na busca.
  List<Cliente> get _clientesFiltrados {
    return _clientes
        .where(
          (cliente) => cliente.nome.toLowerCase().contains(
            _busca.toLowerCase(),
          ),
        )
        .toList();
  }

  // Abre o formulário para cadastrar ou editar.
  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(cliente: cliente),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      await _carregarClientes();
    }
  }

  // Solicita confirmação antes de excluir um cliente.
  Future<void> _excluirCliente(Cliente cliente) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text(
          'Deseja excluir ${cliente.nome} e seus pets? '
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

    if (confirmou != true || cliente.id == null) return;

    try {
      await DatabaseHelper.instancia.excluirCliente(cliente.id!);

      if (!mounted) return;

      await _carregarClientes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente excluído com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      final mensagem = erro is StateError
          ? erro.message
          : 'Não foi possível excluir o cliente.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    }
  }

  // Abre a tela de detalhes do primeiro pet.
  void _abrirDetalhes(Cliente cliente) {
    if (cliente.pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente não possui pets cadastrados.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetalhesScreen(
          pet: cliente.pets.first,
          cliente: cliente,
        ),
      ),
    );
  }

  // Monta um cartão com as ações de editar e excluir.
  Widget _criarCard(Cliente cliente) {
    return ClienteCard(
      cliente: cliente,
      onTap: () => _abrirDetalhes(cliente),
      onEditar: () => _abrirFormulario(cliente: cliente),
      onExcluir: () => _excluirCliente(cliente),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                setState(() => _busca = valor);
              },
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? Center(child: Text(_erro!))
                : _clientesFiltrados.isEmpty
                ? const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final larguraGrande = constraints.maxWidth > 600;

                      if (larguraGrande) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 4,
                              ),
                          itemCount: _clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            return _criarCard(_clientesFiltrados[index]);
                          },
                        );
                      }

                      return ListView.builder(
                        itemCount: _clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          return _criarCard(_clientesFiltrados[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Adicionar novo cliente',
        button: true,
        hint: 'Abre o formulário de cadastro de cliente e pet',
        child: FloatingActionButton(
          heroTag: 'fab_clientes',
          tooltip: 'Adicionar novo cliente',
          onPressed: () => _abrirFormulario(),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }
}
