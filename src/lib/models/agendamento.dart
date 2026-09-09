class Agendamento {
  final String clienteNome;
  final String petNome;
  final DateTime dataHora;
  final String servico; // Banho, Tosa, Banho e Tosa

  Agendamento({
    required this.clienteNome,
    required this.petNome,
    required this.dataHora,
    required this.servico,
  });
}