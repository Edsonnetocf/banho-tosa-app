import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/cliente.dart';
import '../models/pet.dart';
import '../widgets/cliente_card.dart';
import 'cliente_form_screen.dart';
import 'pet_detalhes_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _busca = '';
  Future<void> _formulario([Cliente? cliente]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ClienteFormScreen(cliente: cliente),
      ),
    );
  }

  Future<void> _excluir(Cliente cliente) async {
    final repo = AppScope.read(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text(
          'Deseja excluir ${cliente.nome} e seus pets? Esta ação não poderá ser desfeita.',
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
      await repo.excluirCliente(cliente.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente excluído com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _detalhes(Cliente cliente) async {
    if (cliente.pets.isEmpty) return;
    final Pet? pet = cliente.pets.length == 1
        ? cliente.pets.first
        : await showModalBottomSheet<Pet>(
            context: context,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final pet in cliente.pets)
                    ListTile(
                      title: Text(pet.nome),
                      onTap: () => Navigator.pop(ctx, pet),
                    ),
                ],
              ),
            ),
          );
    if (pet == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PetDetalhesScreen(pet: pet, cliente: cliente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final clientes = repo.clientes
        .where((c) => c.nome.toLowerCase().contains(_busca.toLowerCase()))
        .toList();
    Widget card(Cliente c) => ClienteCard(
      cliente: c,
      onTap: () => _detalhes(c),
      onEditar: repo.podeGravar ? () => _formulario(c) : null,
      onExcluir: repo.podeGravar ? () => _excluir(c) : null,
    );
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
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          Expanded(
            child: clientes.isEmpty
                ? const Center(child: Text('Nenhum cliente encontrado.'))
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth > 600
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 120,
                                ),
                            itemCount: clientes.length,
                            itemBuilder: (_, i) => card(clientes[i]),
                          )
                        : ListView.builder(
                            itemCount: clientes.length,
                            itemBuilder: (_, i) => card(clientes[i]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clientes',
        tooltip: 'Adicionar novo cliente',
        onPressed: repo.podeGravar ? () => _formulario() : null,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
