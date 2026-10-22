class Agendamento {
  final int? id;
  final int? petId;
  final String clienteNome;
  final String petNome;
  final DateTime dataHora;
  final String servico;

  Agendamento({
    this.id,
    this.petId,
    required this.clienteNome,
    required this.petNome,
    required this.dataHora,
    required this.servico,
  });

  factory Agendamento.fromMap(Map<String, Object?> map) {
    return Agendamento(
      id: map['id'] as int,
      petId: map['pet_id'] as int,
      clienteNome: map['cliente_nome'] as String,
      petNome: map['pet_nome'] as String,
      dataHora: DateTime.parse(map['data_hora'] as String),
      servico: map['servico'] as String,
    );
  }
}
