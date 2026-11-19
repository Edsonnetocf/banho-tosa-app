import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../models/cliente.dart';
import '../models/pet.dart';
import '../widgets/foto_pet.dart';
import 'cliente_form_screen.dart';

class PetDetalhesScreen extends StatelessWidget {
  final Pet pet;
  final Cliente cliente;

  const PetDetalhesScreen({
    super.key,
    required this.pet,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final tutor =
        repo.clientes.where((c) => c.id == cliente.id).firstOrNull ?? cliente;
    final atual = tutor.pets.where((p) => p.id == pet.id).firstOrNull ?? pet;
    return Scaffold(
      appBar: AppBar(
        title: Text(atual.nome),
        actions: [
          IconButton(
            tooltip: 'Editar pet',
            onPressed: repo.podeGravar
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          ClienteFormScreen(cliente: tutor, pet: atual),
                    ),
                  )
                : null,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              FotoPet(
                caminho: repo.fotos.caminhoPara(atual.id ?? -1),
                tamanho: 96,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MergeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B6374).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tutor(a): ${tutor.nome}'),
                        Text('Espécie: ${atual.especie}'),
                        Text('Raça: ${atual.raca}'),
                        Text('Porte: ${atual.porte}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Histórico de Atendimentos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Nenhum atendimento registrado ainda.')),
          ),
        ],
      ),
    );
  }
}
