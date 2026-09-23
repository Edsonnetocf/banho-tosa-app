import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/pet.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(pet.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        MergeSemantics(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6374).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tutor(a): ${cliente.nome}'),
                    Text('Espécie: ${pet.especie}'),
                    Text('Raça: ${pet.raca}'),
                    Text('Porte: ${pet.porte}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Histórico de Atendimentos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text('Nenhum atendimento registrado ainda.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}