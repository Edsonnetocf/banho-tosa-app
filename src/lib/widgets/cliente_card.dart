import 'package:flutter/material.dart';

import '../models/cliente.dart';

class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
    this.onEditar,
    this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        minVerticalPadding: 12,
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(cliente.nome),
        subtitle: Text(
          '${cliente.telefone} • ${cliente.pets.length} pet(s)',
        ),
        trailing: onEditar == null && onExcluir == null
            ? const Icon(Icons.chevron_right)
            : PopupMenuButton<String>(
                tooltip: 'Opções do cliente',
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
              ),
        onTap: onTap,
      ),
    );

    if (onEditar == null && onExcluir == null) {
      return MergeSemantics(child: card);
    }

    return card;
  }
}
