import 'pet.dart';

class Cliente {
  final int? id;
  final String nome;
  final String telefone;
  final List<Pet> pets;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.pets = const [],
  });

  factory Cliente.fromMap(
    Map<String, Object?> map, {
    List<Pet> pets = const [],
  }) {
    return Cliente(
      id: map['id'] as int,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String,
      pets: pets,
    );
  }
}
