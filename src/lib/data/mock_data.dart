import '../models/cliente.dart';
import '../models/pet.dart';
import '../models/agendamento.dart';

//lista fixa de clientes, so pra prencher a interface
final List<Cliente> mockClientes = [
  Cliente(
    nome: 'Maria Silva',
    telefone: '(62) 99999-1111',
    pets: [
      Pet(nome: 'Rex', especie: 'Cachorro', raca: 'Labrador', porte: 'Grande'),
    ],
  ),
  Cliente(
    nome: 'João Pereira',
    telefone: '(62) 98888-2222',
    pets: [
      Pet(nome: 'Mimi', especie: 'Gato', raca: 'SRD', porte: 'Pequeno'),
    ],
  ),
  Cliente(
    nome: 'Ana Costa',
    telefone: '(62) 97777-3333',
    pets: [
      Pet(nome: 'Thor', especie: 'Cachorro', raca: 'Poodle', porte: 'Médio'),
    ],
  ),
];

// lista fixa de agendamentos do dia
final List<Agendamento> mockAgendamentos = [
  Agendamento(
    clienteNome: 'Maria Silva',
    petNome: 'Rex',
    dataHora: DateTime.now().add(const Duration(hours: 1)),
    servico: 'Banho e Tosa',
  ),
  Agendamento(
    clienteNome: 'João Pereira',
    petNome: 'Mimi',
    dataHora: DateTime.now().add(const Duration(hours: 3)),
    servico: 'Banho',
  ),
];