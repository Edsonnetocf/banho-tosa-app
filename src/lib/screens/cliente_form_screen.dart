import 'package:flutter/material.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeClienteController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _nomePetController = TextEditingController();
  final _racaController = TextEditingController();

  String _especie = 'Cachorro';
  String _porte = 'Médio';

  @override
  void dispose() {
    _nomeClienteController.dispose();
    _telefoneController.dispose();
    _nomePetController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cliente e Pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Dados do Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeClienteController,
              decoration: const InputDecoration(
                labelText: 'Nome do cliente',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Informe o nome' : null,
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
            const Text('Dados do Pet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomePetController,
              decoration: const InputDecoration(
                labelText: 'Nome do pet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            //menu suspenso (dropdown) outro tipo de entrada de dados
            DropdownButtonFormField<String>(
              initialValue: _especie,
              decoration: const InputDecoration(
                labelText: 'Espécie',
                border: OutlineInputBorder(),
              ),
              items: ['Cachorro', 'Gato', 'Outro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _especie = v!),
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
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _porte = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF0B6374),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  //nesta etapa não salva no banco ainda 
                  //so simula o sucesso e volta para a tela anterior.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente salvo (simulado)!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}