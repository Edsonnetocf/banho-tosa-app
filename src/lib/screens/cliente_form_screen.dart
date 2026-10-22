import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/cliente.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  bool _salvando = false;

  final _formKey = GlobalKey<FormState>();
  final _nomeClienteController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _nomePetController = TextEditingController();
  final _racaController = TextEditingController();

  String _especie = 'Cachorro';
  String _porte = 'Médio';

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();

    final cliente = widget.cliente;

    if (cliente != null) {
      _nomeClienteController.text = cliente.nome;
      _telefoneController.text = cliente.telefone;

      if (cliente.pets.isNotEmpty) {
        final pet = cliente.pets.first;
        _nomePetController.text = pet.nome;
        _racaController.text = pet.raca;
        _especie = pet.especie;
        _porte = pet.porte;
      }
    }
  }

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _nomePetController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _salvando) {
      return;
    }

    setState(() => _salvando = true);

    try {
      final cliente = widget.cliente;

      await DatabaseHelper.instancia.salvarClienteComPet(
        clienteId: cliente?.id,
        petId: cliente != null && cliente.pets.isNotEmpty
            ? cliente.pets.first.id
            : null,
        nomeCliente: _nomeClienteController.text.trim(),
        telefone: _telefoneController.text.trim(),
        nomePet: _nomePetController.text.trim(),
        especie: _especie,
        raca: _racaController.text.trim(),
        porte: _porte,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Cadastro atualizado com sucesso!'
                : 'Cliente e pet cadastrados com sucesso!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o cadastro: $erro')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Cliente e Pet' : 'Novo Cliente e Pet'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Dados do Cliente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeClienteController,
              decoration: const InputDecoration(
                labelText: 'Nome do cliente',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o nome do cliente';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'Dados do Pet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomePetController,
              decoration: const InputDecoration(
                labelText: 'Nome do pet',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o nome do pet';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _especie,
              decoration: const InputDecoration(
                labelText: 'Espécie',
                border: OutlineInputBorder(),
              ),
              items: ['Cachorro', 'Gato', 'Outro']
                  .map(
                    (especie) =>
                        DropdownMenuItem(value: especie, child: Text(especie)),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _especie = valor);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _racaController,
              decoration: const InputDecoration(
                labelText: 'Raça',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _porte,
              decoration: const InputDecoration(
                labelText: 'Porte',
                border: OutlineInputBorder(),
              ),
              items: ['Pequeno', 'Médio', 'Grande']
                  .map(
                    (porte) =>
                        DropdownMenuItem(value: porte, child: Text(porte)),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _porte = valor);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF0B6374),
              ),
              onPressed: _salvando ? null : _salvar,
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
                      _editando ? 'Salvar Alterações' : 'Salvar',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
