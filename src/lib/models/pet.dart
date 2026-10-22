class Pet {
  final int? id;
  final int? clienteId;
  final String nome;
  final String especie;
  final String raca;
  final String porte;

  Pet({
    this.id,
    this.clienteId,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.porte,
  });

  factory Pet.fromMap(Map<String, Object?> map) {
    return Pet(
      id: map['id'] as int,
      clienteId: map['cliente_id'] as int,
      nome: map['nome'] as String,
      especie: map['especie'] as String,
      raca: map['raca'] as String,
      porte: map['porte'] as String,
    );
  }
}
