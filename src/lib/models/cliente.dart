import 'pet.dart';

class Cliente {
  final String nome;
  final String telefone;
  final List<Pet> pets;

  Cliente({
    required this.nome,
    required this.telefone,
    this.pets = const [],
  });
}