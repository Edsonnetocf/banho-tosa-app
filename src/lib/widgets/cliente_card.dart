import 'package:flutter/material.dart';
import '../models/cliente.dart';

//widget reutilizvel: um cartão que representa um cliente na lista
class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(cliente.nome),
        subtitle: Text(
          '${cliente.telefone} • ${cliente.pets.length} pet(s)',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}