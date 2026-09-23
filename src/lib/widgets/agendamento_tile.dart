import 'package:flutter/material.dart';

import '../models/agendamento.dart';

//widget reutilizável: uma linha da lista de agendamentos
class AgendamentoTile extends StatelessWidget {
  final Agendamento agendamento;

  const AgendamentoTile({super.key, required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final hora =
        '${agendamento.dataHora.hour.toString().padLeft(2, '0')}:${agendamento.dataHora.minute.toString().padLeft(2, '0')}';

    return MergeSemantics(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              //bloco de horário
              Column(
                children: [
                  Text(
                    hora,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              //informacoes do agendamento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${agendamento.petNome} (${agendamento.clienteNome})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(agendamento.servico),
                  ],
                ),
              ),
              ExcludeSemantics(child: const Icon(Icons.pets)),
            ],
          ),
        ),
      ),
    );
  }
}
