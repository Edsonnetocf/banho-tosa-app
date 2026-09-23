import 'package:flutter/material.dart';

import '../data/mock_data.dart';
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
  String _busca = '';

  List<Cliente> get _clientesFiltrados {
    if (_busca.isEmpty) return mockClientes;
    return mockClientes
        .where((c) => c.nome.toLowerCase().contains(_busca.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          //campo de busca (elemento de entrada de dados)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) => setState(() => _busca = valor),
            ),
          ),
          //o LayoutBuilder adapta a lista conforme a largura da tela
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larguraGrande = constraints.maxWidth > 600;

                if (larguraGrande) {
                  //telas largas: usa grid com 2 colunas
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                        ),
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientesFiltrados[index];
                      return ClienteCard(
                        cliente: cliente,
                        onTap: () => _abrirDetalhes(cliente),
                      );
                    },
                  );
                }

                //telas estreitas: lista vertical simples
                return ListView.builder(
                  itemCount: _clientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientesFiltrados[index];
                    return ClienteCard(
                      cliente: cliente,
                      onTap: () => _abrirDetalhes(cliente),
                    );
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
          tooltip: 'Adicionar novo cliente',
          child: const Icon(Icons.person_add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClienteFormScreen()),
            );
          },
        ),
      ),
    );
  }

  void _abrirDetalhes(Cliente cliente) {
    if (cliente.pets.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PetDetalhesScreen(pet: cliente.pets.first, cliente: cliente),
      ),
    );
  }
}
