import 'package:flutter/material.dart';

import '../models/agendamento.dart';
import 'foto_pet.dart';

class AgendamentoTile extends StatelessWidget {
  final Agendamento agendamento;
  final String? caminhoFoto;
  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const AgendamentoTile({
    super.key,
    required this.agendamento,
    this.caminhoFoto,
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
            FotoPet(caminho: caminhoFoto),
            const SizedBox(width: 12),
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
                  Text('$data • $hora'),
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
