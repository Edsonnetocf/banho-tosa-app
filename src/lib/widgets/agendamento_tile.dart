import 'package:flutter/material.dart';

import '../models/agendamento.dart';

class AgendamentoTile extends StatelessWidget {
  final Agendamento agendamento;
  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const AgendamentoTile({
    super.key,
    required this.agendamento,
    this.onEditar,
    this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final hora =
        '${agendamento.dataHora.hour.toString().padLeft(2, '0')}:'
        '${agendamento.dataHora.minute.toString().padLeft(2, '0')}';

    final data =
        '${agendamento.dataHora.day.toString().padLeft(2, '0')}/'
        '${agendamento.dataHora.month.toString().padLeft(2, '0')}/'
        '${agendamento.dataHora.year}';

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(data),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${agendamento.petNome} (${agendamento.clienteNome})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(agendamento.servico),
                ],
              ),
            ),
            if (onEditar != null || onExcluir != null)
              PopupMenuButton<String>(
                tooltip: 'Opções do agendamento',
                onSelected: (opcao) {
                  if (opcao == 'editar') {
                    onEditar?.call();
                  } else if (opcao == 'excluir') {
                    onExcluir?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text('Excluir'),
                  ),
                ],
              )
            else
              const ExcludeSemantics(
                child: Icon(Icons.pets),
              ),
          ],
        ),
      ),
    );

    if (onEditar == null && onExcluir == null) {
      return MergeSemantics(child: card);
    }

    return card;
  }
}
